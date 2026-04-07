import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/diagnosis_provider.dart';
import '../utils/disease_data.dart';
import '../widgets/diagnosis_card.dart';
import 'diagnose_screen.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    _DashboardTab(),
    DiagnoseScreen(),
    HistoryScreen(),
    MapScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech),
            label: 'Diagnóstico',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Biblioteca',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final stats = provider.diseaseStats;
    final recent = provider.history.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.coffee, color: Colors.white),
            const SizedBox(width: 8),
            const Text('DECAFIA'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DiagnosisProvider>().loadHistory(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Hero card ────────────────────────────────────────────
            _HeroCard(
              onDiagnose: () {
                // Switch to Diagnose tab via HomeScreen state
                final state = context
                    .findAncestorStateOfType<_HomeScreenState>();
                state?.setState(() => state._currentIndex = 1);
              },
            ),
            const SizedBox(height: 20),

            // ── Summary stats ────────────────────────────────────────
            Text('Resumen',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SummaryGrid(
              total: provider.history.length,
              withLocation: provider.historyWithLocation.length,
              diseases: stats.keys
                  .where((k) => k != 'sano')
                  .length,
            ),
            const SizedBox(height: 20),

            // ── Disease breakdown ────────────────────────────────────
            if (stats.isNotEmpty) ...[
              Text('Distribución de enfermedades',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _DiseaseBreakdown(stats: stats),
              const SizedBox(height: 20),
            ],

            // ── Recent diagnoses ─────────────────────────────────────
            if (recent.isNotEmpty) ...[
              Row(
                children: [
                  Text('Recientes',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final state = context
                          .findAncestorStateOfType<_HomeScreenState>();
                      state?.setState(() => state._currentIndex = 2);
                    },
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...recent.map((d) => DiagnosisCard(
                    diagnosis: d,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ResultScreen(diagnosis: d)),
                    ),
                  )),
            ] else
              _EmptyState(
                onDiagnose: () {
                  final state = context
                      .findAncestorStateOfType<_HomeScreenState>();
                  state?.setState(() => state._currentIndex = 1);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onDiagnose;
  const _HeroCard({required this.onDiagnose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C2A), Color(0xFF1A7A43)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C2A).withAlpha(100),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detección de enfermedades\ndel café con IA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analiza hojas de café y detecta roya,\nmancha de hierro, ojo de gallo y más.',
            style: TextStyle(
                color: Colors.white.withAlpha(200), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onDiagnose,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F4C2A),
            ),
            icon: const Icon(Icons.biotech),
            label: const Text('Nuevo diagnóstico'),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final int total;
  final int withLocation;
  final int diseases;

  const _SummaryGrid({
    required this.total,
    required this.withLocation,
    required this.diseases,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
            value: total, label: 'Análisis', icon: Icons.biotech),
        const SizedBox(width: 8),
        _StatCard(
            value: diseases,
            label: 'Enfermedades',
            icon: Icons.warning_amber),
        const SizedBox(width: 8),
        _StatCard(
            value: withLocation,
            label: 'En mapa',
            icon: Icons.location_on),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;

  const _StatCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DiseaseBreakdown extends StatelessWidget {
  final Map<String, int> stats;

  const _DiseaseBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.values.fold(0, (a, b) => a + b);
    return Column(
      children: stats.entries.map((e) {
        final fraction = total > 0 ? e.value / total : 0.0;
        final color = diseaseColor(e.key);
        final name = kDiseaseInfo[e.key]?['nameEs'] ?? e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(name,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: color.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text('${e.value}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onDiagnose;
  const _EmptyState({required this.onDiagnose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.coffee,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha(80)),
            const SizedBox(height: 16),
            Text(
              'Sin diagnósticos aún',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onDiagnose,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Analizar primera muestra'),
            ),
          ],
        ),
      ),
    );
  }
}
