import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diagnosis.dart';
import '../providers/diagnosis_provider.dart';
import '../services/ml_service.dart';
import '../utils/disease_data.dart';

class ResultScreen extends StatefulWidget {
  final Diagnosis diagnosis;

  const ResultScreen({super.key, required this.diagnosis});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _notesController = TextEditingController();
  bool _saved = false;
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final d = widget.diagnosis.copyWith(notes: _notesController.text.trim());
    await context.read<DiagnosisProvider>().saveDiagnosis(d);
    if (!mounted) return;
    setState(() {
      _saved = true;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnóstico guardado'),
        backgroundColor: Color(0xFF0F4C2A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diagnosis;
    final info = kDiseaseInfo[d.disease];
    final color = diseaseColor(d.disease);
    final name = info?['nameEs'] ?? d.disease;
    final severity = info?['severity'] ?? 'unknown';
    final provider = context.watch<DiagnosisProvider>();
    final probs = provider.lastProbabilities;
    final lesionCount = provider.lastLesionCount;
    final failureMode = provider.failureMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        actions: [
          if (!_saved && d.disease != 'model_unavailable')
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text('Guardar',
                  style: TextStyle(color: Colors.white)),
            ),
          if (_saved)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.check_circle, color: Colors.greenAccent),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: File(d.imagePath).existsSync()
                  ? Image.file(File(d.imagePath),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover)
                  : Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 60),
                    ),
            ),
            const SizedBox(height: 20),

            // Primary result
            if (d.disease == 'model_unavailable')
              _ModelUnavailableCard(
                  mode: failureMode ?? MlFailureMode.inferenceError)
            else if (d.disease == 'no_detection')
              const _NoDetectionCard()
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(diseaseIcon(d.disease), color: color, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor(severity),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severityLabel(severity),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ConfidenceBar(
                        label: 'Confianza', value: d.confidence, color: color),
                    if (d.disease != 'sano') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.grid_view_rounded,
                              size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(
                            'Lesiones detectadas: $lesionCount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // All probabilities
            if (probs.isNotEmpty) ...[
              Text('Probabilidades',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...probs.entries.map((e) {
                final c = diseaseColor(e.key);
                final n =
                    kDiseaseInfo[e.key]?['nameEs'] ?? e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ConfidenceBar(
                      label: n, value: e.value, color: c, small: true),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Description
            if (info != null) ...[
              _InfoSection('Descripción', info['description']!),
              _InfoSection('Síntomas', info['symptoms']!),
              _InfoSection('Tratamiento', info['treatment']!),
            ],

            // Location
            if (d.latitude != null) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on,
                    color: Color(0xFF0F4C2A)),
                title: const Text('Ubicación registrada'),
                subtitle: Text(
                    '${d.latitude!.toStringAsFixed(5)}, '
                    '${d.longitude!.toStringAsFixed(5)}'),
              ),
            ],

            // Notes and Save — hidden for model errors (nothing to persist)
            if (d.disease != 'model_unavailable') ...[
              const Divider(),
              const SizedBox(height: 8),
              Text('Notas (opcional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Agrega observaciones sobre esta muestra...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),
              if (!_saved)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C2A),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar diagnóstico'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool small;

  const _ConfidenceBar({
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: small ? 12 : 14,
                  fontWeight:
                      small ? FontWeight.normal : FontWeight.w600,
                  color: small ? Colors.grey.shade700 : color,
                ),
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: small ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withAlpha(30),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: small ? 4 : 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const _InfoSection(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(content,
              style: TextStyle(
                  color: Colors.grey.shade700, height: 1.5)),
        ],
      ),
    );
  }
}

class _NoDetectionCard extends StatelessWidget {
  const _NoDetectionCard();

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey.shade700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.search_off_rounded,
                  color: Colors.grey.shade600, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No se detectaron síntomas en esta imagen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Para obtener un resultado confiable:',
            style: TextStyle(fontWeight: FontWeight.w600, color: grey),
          ),
          const SizedBox(height: 8),
          for (final tip in const [
            'Acerca la cámara a una sola hoja.',
            'Asegúrate de que la hoja ocupe la mayor parte de la imagen.',
            'Usa luz natural directa; evita sombras y reflejos.',
            'Revisa otras hojas antes de concluir que la planta está sana.',
          ])
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: grey)),
                  Expanded(
                    child: Text(tip,
                        style: TextStyle(color: grey, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModelUnavailableCard extends StatelessWidget {
  final MlFailureMode mode;
  const _ModelUnavailableCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final (heading, body) = switch (mode) {
      MlFailureMode.timeout => (
          'El análisis tardó demasiado',
          'El modelo no completó la inferencia a tiempo. '
              'Cierra aplicaciones en segundo plano y vuelve a intentarlo.',
        ),
      MlFailureMode.inferenceError => (
          'Error al procesar la imagen',
          'Ocurrió un error durante el análisis. '
              'Selecciona otra imagen o vuelve a intentarlo.',
        ),
      MlFailureMode.modelMissing => (
          'Modelo no disponible en esta instalación',
          'El archivo del modelo no se encontró. '
              'Reinstala la aplicación o contacta al equipo de DECAFIA.',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  heading,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(color: Colors.red.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }
}
