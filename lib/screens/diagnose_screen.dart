import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/diagnosis_provider.dart';
import '../services/location_service.dart';
import '../services/ml_service.dart';
import 'result_screen.dart';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  File? _selectedImage;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    final provider = context.read<DiagnosisProvider>();

    // Capture GPS; fall back to El Socorro, Santander if unavailable
    double? lat, lon;
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      lat = pos.latitude;
      lon = pos.longitude;
    } else {
      lat = 6.441083;
      lon = -73.215445;
    }

    final result = await provider.analyze(_selectedImage!.path, lat: lat, lon: lon);
    if (!mounted) return;

    if (result != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(diagnosis: result),
        ),
      );
      setState(() => _selectedImage = null);
      provider.resetState();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Error al analizar la imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosisProvider>().state;
    final isAnalyzing = state == AnalysisState.analyzing;
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico')),
      body: Column(
        children: [
          // Model status banner
          if (!MlService.instance.isModelLoaded)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo demo: coloca decafia.onnx en assets/models/ para activar el modelo real.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // Image preview area
          Expanded(
            child: _selectedImage == null
                ? _buildPlaceholder(color)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_selectedImage!, fit: BoxFit.contain),
                      if (isAnalyzing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'Analizando...',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_selectedImage == null || isAnalyzing) ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    icon: isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.biotech),
                    label: Text(isAnalyzing ? 'Analizando...' : 'Analizar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 100, color: color.withAlpha(80)),
          const SizedBox(height: 16),
          Text(
            'Selecciona o toma una foto\nde la hoja de café',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
