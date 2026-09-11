import 'package:flutter/foundation.dart';
import '../models/diagnosis.dart';
import '../services/database_service.dart';
import '../services/ml_service.dart';

enum AnalysisState { idle, analyzing, done, error }

class DiagnosisProvider extends ChangeNotifier {
  List<Diagnosis> _history = [];
  AnalysisState _state = AnalysisState.idle;
  Map<String, double> _lastProbabilities = {};
  bool _noDetection = false;
  MlFailureMode? _failureMode;
  int _lastLesionCount = 1;
  String? _errorMessage;
  bool _isLoading = false;

  List<Diagnosis> get history => List.unmodifiable(_history);
  AnalysisState get state => _state;
  Map<String, double> get lastProbabilities =>
      Map.unmodifiable(_lastProbabilities);
  bool get noDetection => _noDetection;
  MlFailureMode? get failureMode => _failureMode;
  int get lastLesionCount => _lastLesionCount;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // ── History management ────────────────────────────────────────────────────

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _history = await DatabaseService.instance.getAllDiagnoses();
    _isLoading = false;
    notifyListeners();
  }

  Future<Diagnosis?> analyze(String imagePath,
      {double? lat, double? lon}) async {
    _state = AnalysisState.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MlService.instance.classify(imagePath);
      _lastLesionCount = MlService.instance.lastLesionCount;

      final String disease;
      final double confidence;
      if (result is MlDetections) {
        _lastProbabilities = result.scores;
        _noDetection = false;
        _failureMode = null;
        disease = result.scores.entries.first.key;
        confidence = result.scores.entries.first.value;
      } else if (result is MlNoDetection) {
        _lastProbabilities = {};
        _noDetection = true;
        _failureMode = null;
        disease = 'no_detection';
        confidence = 0.0;
      } else {
        // MlModelUnavailable — model failed; no fabricated values; no SQLite write
        final unavailable = result as MlModelUnavailable;
        _lastProbabilities = {};
        _noDetection = false;
        _failureMode = unavailable.mode;
        disease = 'model_unavailable';
        confidence = 0.0;
      }

      final d = Diagnosis(
        imagePath: imagePath,
        disease: disease,
        confidence: confidence,
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
      );

      _state = AnalysisState.done;
      notifyListeners();
      return d;
    } catch (e) {
      _state = AnalysisState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Diagnosis> saveDiagnosis(Diagnosis d) async {
    final id = await DatabaseService.instance.insertDiagnosis(d);
    final saved = d.copyWith(id: id);
    _history.insert(0, saved);
    notifyListeners();
    return saved;
  }

  Future<void> deleteDiagnosis(int id) async {
    await DatabaseService.instance.deleteDiagnosis(id);
    _history.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Future<void> updateNotes(int id, String notes) async {
    await DatabaseService.instance.updateNotes(id, notes);
    final idx = _history.indexWhere((d) => d.id == id);
    if (idx != -1) {
      _history[idx] = _history[idx].copyWith(notes: notes);
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    await DatabaseService.instance.clearAll();
    _history = [];
    notifyListeners();
  }

  void resetState() {
    _state = AnalysisState.idle;
    _lastProbabilities = {};
    _noDetection = false;
    _failureMode = null;
    _lastLesionCount = 1;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Map<String, int> get diseaseStats {
    final stats = <String, int>{};
    for (final d in _history) {
      stats[d.disease] = (stats[d.disease] ?? 0) + 1;
    }
    return stats;
  }

  List<Diagnosis> get historyWithLocation =>
      _history.where((d) => d.latitude != null && d.longitude != null).toList();
}
