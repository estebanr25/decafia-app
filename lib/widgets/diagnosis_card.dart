import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diagnosis.dart';
import '../utils/disease_data.dart';

class DiagnosisCard extends StatelessWidget {
  final Diagnosis diagnosis;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DiagnosisCard({
    super.key,
    required this.diagnosis,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final info = kDiseaseInfo[diagnosis.disease];
    final color = diseaseColor(diagnosis.disease);
    final name = info?['nameEs'] ?? diagnosis.disease;
    final severity = info?['severity'] ?? 'unknown';
    final _showConfidence = diagnosis.disease != 'no_detection' &&
        diagnosis.disease != 'model_unavailable';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 80,
              height: 80,
              child: File(diagnosis.imagePath).existsSync()
                  ? Image.file(File(diagnosis.imagePath), fit: BoxFit.cover)
                  : Container(
                      color: color.withAlpha(30),
                      child: Icon(diseaseIcon(diagnosis.disease),
                          color: color, size: 36),
                    ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor(severity).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            severityLabel(severity),
                            style: TextStyle(
                              fontSize: 10,
                              color: severityColor(severity),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showConfidence) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: diagnosis.confidence,
                        backgroundColor: color.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_showConfidence)
                          Text(
                            '${(diagnosis.confidence * 100).toStringAsFixed(1)}% confianza',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(diagnosis.timestamp),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    if (diagnosis.latitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Text(
                              '${diagnosis.latitude!.toStringAsFixed(4)}, '
                              '${diagnosis.longitude!.toStringAsFixed(4)}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
          ],
        ),
      ),
    );
  }
}
