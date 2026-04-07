import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diagnosis.dart';
import '../providers/diagnosis_provider.dart';
import '../utils/disease_data.dart';
import '../widgets/diagnosis_card.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, Diagnosis d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar diagnóstico'),
        content: const Text(
            '¿Eliminar este diagnóstico del historial?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<DiagnosisProvider>().deleteDiagnosis(d.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          if (provider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Limpiar todo',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpiar historial'),
                    content: const Text(
                        '¿Eliminar todos los diagnósticos guardados?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar todo',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<DiagnosisProvider>().clearHistory();
                }
              },
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.history.isEmpty
              ? _buildEmpty(context)
              : Column(
                  children: [
                    _StatsBar(provider: provider),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: provider.history.length,
                        itemBuilder: (ctx, i) {
                          final d = provider.history[i];
                          return DiagnosisCard(
                            diagnosis: d,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ResultScreen(diagnosis: d)),
                            ),
                            onDelete: d.id != null
                                ? () => _confirmDelete(context, d)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withAlpha(80)),
          const SizedBox(height: 16),
          Text(
            'Sin diagnósticos guardados',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa la pestaña Diagnóstico para analizar\nuna hoja de café.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final DiagnosisProvider provider;

  const _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = provider.diseaseStats;
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: stats.entries.map((e) {
          final color = diseaseColor(e.key);
          final name =
              kDiseaseInfo[e.key]?['nameEs'] ?? e.key;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${e.value}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                Text(name,
                    style:
                        TextStyle(fontSize: 10, color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
