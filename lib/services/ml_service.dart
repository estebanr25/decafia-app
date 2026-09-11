import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import '../utils/disease_data.dart';

// YOLOv8m was trained at 640×640
const int _kInputSize = 640;
const String _kModelAsset = 'assets/models/decafia_best.onnx';
const Duration _kTimeout = Duration(seconds: 15);
const double _kConfThreshold = 0.50;

// YOLOv8 ONNX output: [1, 8, 8400]
//   channels 0-3 → bbox (cx, cy, w, h) normalised
//   channels 4-7 → class scores: Roya, Coco, Sano, Minador
const List<String> _kYoloClasses = ['roya', 'coco', 'sano', 'minador'];

// ── Isolate-safe preprocessing ────────────────────────────────────────────────
// YOLOv8 expects pixel values in [0, 1] — divide by 255 only, no mean/std.

Float32List _preprocessBytes(Uint8List rawBytes) {
  img.Image? image = img.decodeImage(rawBytes);
  if (image == null) throw Exception('Cannot decode image');

  image = img.copyResize(image,
      width: _kInputSize,
      height: _kInputSize,
      interpolation: img.Interpolation.linear);

  // CHW layout [C, H, W] — required by YOLOv8 ONNX
  final buffer = Float32List(3 * _kInputSize * _kInputSize);
  for (int y = 0; y < _kInputSize; y++) {
    for (int x = 0; x < _kInputSize; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;
      buffer[0 * _kInputSize * _kInputSize + y * _kInputSize + x] = r;
      buffer[1 * _kInputSize * _kInputSize + y * _kInputSize + x] = g;
      buffer[2 * _kInputSize * _kInputSize + y * _kInputSize + x] = b;
    }
  }
  return buffer;
}

// ── Inference result type ────────────────────────────────────────────────────

enum MlFailureMode { timeout, inferenceError, modelMissing }

sealed class MlResult {}

/// Real model output: at least one class scored ≥ [_kConfThreshold].
/// [scores] is sorted descending by value; keys are [_kYoloClasses] labels.
class MlDetections extends MlResult {
  final Map<String, double> scores;
  MlDetections(this.scores);
}

/// Model ran but no class scored ≥ [_kConfThreshold].
/// No numeric confidence is fabricated; the UI must show a neutral message.
class MlNoDetection extends MlResult {}

/// Model failed before or during inference.
/// No numeric values are fabricated; [mode] identifies the failure category.
class MlModelUnavailable extends MlResult {
  final MlFailureMode mode;
  final String reason;
  MlModelUnavailable(this.mode, this.reason);
}

// ─────────────────────────────────────────────────────────────────────────────

class MlService {
  MlService._();
  static final MlService instance = MlService._();

  OrtSession? _session;
  bool _initialized = false;
  bool _modelMissing = false;
  Future<void>? _initFuture;
  int _lastLesionCount = 1;

  int get lastLesionCount => _lastLesionCount;

  Future<void> _doInit() async {
    try {
      print('ML: initializing OrtEnv');
      OrtEnv.instance.init();

      print('ML: loading model asset ($_kModelAsset)');
      final bytes =
          (await rootBundle.load(_kModelAsset)).buffer.asUint8List();
      print('ML: model bytes loaded (${bytes.lengthInBytes} bytes)');

      final opts = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, opts);
      print('ML: OrtSession created successfully');
    } catch (e) {
      print('ML: init failed — $e');
      _modelMissing = true;
    } finally {
      _initialized = true;
    }
  }

  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  // ── Public entry point ────────────────────────────────────────────────────

  /// Returns an [MlResult] sorted descending by score.
  /// Always resolves within [_kTimeout]; falls back to [_mockResult] on error.
  Future<MlResult> classify(String imagePath) async {
    print('ML: starting analysis');
    print('ML: model loaded = $isModelLoaded');

    final imageFile = File(imagePath);
    print('ML: image size = ${imageFile.lengthSync()} bytes');

    try {
      final result = await _runClassify(imagePath).timeout(
        _kTimeout,
        onTimeout: () {
          print('ML: TIMEOUT after ${_kTimeout.inSeconds}s');
          return MlModelUnavailable(MlFailureMode.timeout,
              'Inference timed out after ${_kTimeout.inSeconds}s');
        },
      );
      print('ML: inference complete, result = $result');
      return result;
    } catch (e) {
      print('ML: classify error — $e');
      return MlModelUnavailable(MlFailureMode.inferenceError, e.toString());
    }
  }

  Future<MlResult> _runClassify(String imagePath) async {
    await init();

    if (_modelMissing || _session == null) {
      print('ML: model not available — $_kModelAsset not loaded');
      return MlModelUnavailable(
          MlFailureMode.modelMissing, '$_kModelAsset not loaded');
    }

    // Preprocess in background isolate
    final rawBytes = await File(imagePath).readAsBytes();
    final input = await compute(_preprocessBytes, rawBytes);

    final inputTensor = OrtValueTensor.createTensorWithDataList(
        input, [1, 3, _kInputSize, _kInputSize]);
    final runOptions = OrtRunOptions();

    print('ML: running ONNX inference (input ${_kInputSize}×${_kInputSize})');
    // YOLOv8 ONNX input node is named 'images'
    final outputs =
        await _session!.runAsync(runOptions, {'images': inputTensor});

    inputTensor.release();
    runOptions.release();

    if (outputs == null || outputs.isEmpty || outputs[0] == null) {
      throw Exception('Empty output from ONNX session');
    }

    // ── Parse YOLOv8 output: shape [1, 8, 8400] ──────────────────────────
    // onnxruntime returns this as List<List<List<double>>>
    // [batch=1][channel=8][detection=8400]
    final rawOutput = outputs[0]!.value as List<List<List<double>>>;
    final result = _parseYoloOutput(rawOutput);

    for (final o in outputs) {
      o?.release();
    }

    return result;
  }

  // ── YOLOv8 output parser ──────────────────────────────────────────────────

  MlResult _parseYoloOutput(List<List<List<double>>> rawOutput) {
    // rawOutput[0] → shape [8][8400]
    // channels 0-3: bbox (cx, cy, w, h)
    // channels 4-7: class scores for [Roya, Coco, Sano, Minador]
    final channels = rawOutput[0]; // [8][8400]
    const numDetections = 8400;
    const numClasses = 4;

    // Track the highest score seen per class across all 8400 anchors
    final bestScore = List<double>.filled(numClasses, 0.0);

    for (int i = 0; i < numDetections; i++) {
      for (int c = 0; c < numClasses; c++) {
        final score = channels[4 + c][i];
        if (score > bestScore[c]) bestScore[c] = score;
      }
    }

    print('ML: best scores per class — '
        'roya=${bestScore[0].toStringAsFixed(3)} '
        'coco=${bestScore[1].toStringAsFixed(3)} '
        'sano=${bestScore[2].toStringAsFixed(3)} '
        'minador=${bestScore[3].toStringAsFixed(3)}');

    // Check whether any class exceeded the confidence threshold
    final anyDetected = bestScore.any((s) => s >= _kConfThreshold);

    if (!anyDetected) {
      print('ML: no detection above threshold (${_kConfThreshold})');
      _lastLesionCount = 0;
      return MlNoDetection();
    }

    // Find top class index (highest bestScore)
    int topClassIdx = 0;
    for (int c = 1; c < numClasses; c++) {
      if (bestScore[c] > bestScore[topClassIdx]) topClassIdx = c;
    }

    // Count anchor proposals above threshold for the top class
    int lesionCount = 0;
    for (int i = 0; i < numDetections; i++) {
      if (channels[4 + topClassIdx][i] >= _kConfThreshold) lesionCount++;
    }
    _lastLesionCount = lesionCount > 0 ? lesionCount : 1;
    print('ML: lesion count for top class (${_kYoloClasses[topClassIdx]}) = $_lastLesionCount');

    // Build result map and sort descending by score
    final result = <String, double>{};
    for (int c = 0; c < numClasses; c++) {
      result[_kYoloClasses[c]] = bestScore[c];
    }
    return MlDetections(Map.fromEntries(
        result.entries.toList()..sort((a, b) => b.value.compareTo(a.value))));
  }

  bool get isModelLoaded => _initialized && !_modelMissing && _session != null;
}
