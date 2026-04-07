import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/diagnosis_provider.dart';
import '../services/ml_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final count = provider.history.length;
    final modelLoaded = MlService.instance.isModelLoaded;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // ── App info ────────────────────────────────────────────────
          _SectionHeader('Aplicación'),
          _InfoTile(
            icon: Icons.info_outline,
            title: 'DECAFIA',
            subtitle: 'Detección de enfermedades del café con IA · v1.0.0',
          ),
          _InfoTile(
            icon: modelLoaded ? Icons.check_circle : Icons.warning_amber,
            iconColor: modelLoaded
                ? const Color(0xFF2E7D32)
                : Colors.amber.shade700,
            title: 'Modelo de IA',
            subtitle: modelLoaded
                ? 'Modelo ONNX cargado correctamente'
                : 'Modelo no encontrado — modo demo activo.\n'
                    'Coloca decafia.onnx en assets/models/',
          ),

          // ── Data ───────────────────────────────────────────────────
          _SectionHeader('Datos'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Diagnósticos guardados'),
            trailing: Text(
              '$count',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Limpiar historial',
                style: TextStyle(color: Colors.red)),
            onTap: count == 0
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Limpiar historial'),
                        content: Text(
                            '¿Eliminar los $count diagnósticos guardados? Esta acción no se puede deshacer.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, true),
                            child: const Text('Eliminar',
                                style:
                                    TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context
                          .read<DiagnosisProvider>()
                          .clearHistory();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Historial eliminado')),
                        );
                      }
                    }
                  },
          ),

          // ── Enfermedades ───────────────────────────────────────────
          _SectionHeader('Enfermedades detectadas'),
          const _DiseaseReference(),

          // ── About ──────────────────────────────────────────────────
          _SectionHeader('Acerca de'),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Proyecto académico'),
            subtitle: const Text(
                'Desarrollado como proyecto de investigación en '
                'detección temprana de enfermedades del café.'),
          ),
          ListTile(
            leading: const Icon(Icons.coffee),
            title: const Text('Cultivos objetivo'),
            subtitle: const Text(
                'Coffea arabica · Variedades Colombia, Castillo, '
                'Caturra · Zonas cafeteras de Colombia'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _DiseaseReference extends StatelessWidget {
  const _DiseaseReference();

  @override
  Widget build(BuildContext context) {
    const diseases = [
      ('Planta Sana', 'Sin síntomas de enfermedad · Sin riesgo'),
      ('Roya del Cafeto', 'Hemileia vastatrix · Riesgo alto'),
      ('Cochinilla (Coco)', 'Coccinellidae · Riesgo medio'),
      ('Minador de la Hoja', 'Leucoptera coffeella · Riesgo medio'),
    ];

    return Column(
      children: diseases
          .map((d) => ListTile(
                dense: true,
                leading: const Icon(Icons.local_florist,
                    size: 18, color: Color(0xFF0F4C2A)),
                title: Text(d.$1,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(d.$2,
                    style: const TextStyle(fontSize: 12)),
              ))
          .toList(),
    );
  }
}
