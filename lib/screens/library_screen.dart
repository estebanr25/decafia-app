import 'package:flutter/material.dart';
import '../utils/disease_data.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Enfermedades'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DiseaseCard(
            diseaseKey: 'roya',
            scientificName: 'Hemileia vastatrix',
            symptoms: 'Manchas amarillo-naranja en la cara inferior de la hoja. '
                'Las lesiones crecen y producen pústulas con esporas anaranjadas. '
                'Las hojas afectadas caen prematuramente causando defoliación severa.',
            conditions: '21–25 °C de temperatura y humedad relativa superior al 80%. '
                'Favorecida por períodos prolongados de lluvia y sombra excesiva.',
            impact: 'Hasta 30% de pérdida de cosecha en infestaciones severas. '
                'Principal enfermedad fúngica del café a nivel mundial.',
            treatment: 'Fungicida cúprico (hidróxido de cobre) a 3 g/litro. '
                'Aplicar cada 21 días en época lluviosa. '
                'Complementar con triazoles (propiconazol) en focos activos.',
            urgencyLabel: 'ALTA — tratar en 48 horas',
            urgencyColor: Color(0xFFC62828),
            costNote: 'COP 25,000–45,000 por litro de fungicida cúprico.',
          ),
          SizedBox(height: 16),
          _DiseaseCard(
            diseaseKey: 'coco',
            scientificName: 'Coccinellidae',
            symptoms: 'Masas algodonosas o cerosas blancas en tallos, ramas y hojas. '
                'Amarillamiento y caída prematura de hojas. '
                'Presencia de fumagina (hollín negro) sobre partes afectadas.',
            conditions: 'Épocas secas con alta temperatura (24–30 °C). '
                'Favorecida por déficit hídrico y falta de control de malezas.',
            impact: 'Reducción del vigor de la planta y pérdida de producción '
                'del 10–25% en infestaciones severas. La fumagina reduce fotosíntesis.',
            treatment: 'Imidacloprid 350 SC (0.5 ml/litro) al suelo o follaje. '
                'Control biológico con Cryptolaemus montrouzieri. '
                'Lavado con solución jabonosa en focos iniciales.',
            urgencyLabel: 'MEDIA — revisar en 5 días',
            urgencyColor: Color(0xFF1565C0),
            costNote: 'COP 35,000–55,000 por litro de Imidacloprid 350 SC.',
          ),
          SizedBox(height: 16),
          _DiseaseCard(
            diseaseKey: 'minador',
            scientificName: 'Leucoptera coffeella',
            symptoms: 'Manchas translúcidas blanco-amarillentas en el haz de la hoja. '
                'Al trasluz se observan galerías irregulares con larvas o pupas. '
                'Defoliación en ataques masivos reduce la fotosíntesis.',
            conditions: 'Épocas secas con temperaturas de 22–28 °C. '
                'Alta incidencia solar directa y fincas con poca sombra regulada.',
            impact: 'Reducción del área foliar activa en hasta 40% en brotes severos. '
                'Debilita la planta y predispone a otras enfermedades.',
            treatment: 'Control biológico con parasitoide Mirax insularis. '
                'Regular la sombra para reducir temperatura foliar. '
                'Imidacloprid sistémico (0.5 ml/litro) en focos de alta infestación.',
            urgencyLabel: 'MEDIA — monitorear semanalmente',
            urgencyColor: Color(0xFFF57F17),
            costNote: 'COP 30,000–50,000 por tratamiento con Bt.',
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Disease card ──────────────────────────────────────────────────────────────

class _DiseaseCard extends StatelessWidget {
  final String diseaseKey;
  final String scientificName;
  final String symptoms;
  final String conditions;
  final String impact;
  final String treatment;
  final String urgencyLabel;
  final Color urgencyColor;
  final String costNote;

  const _DiseaseCard({
    required this.diseaseKey,
    required this.scientificName,
    required this.symptoms,
    required this.conditions,
    required this.impact,
    required this.treatment,
    required this.urgencyLabel,
    required this.urgencyColor,
    required this.costNote,
  });

  @override
  Widget build(BuildContext context) {
    final color = diseaseColor(diseaseKey);
    final icon = diseaseIcon(diseaseKey);
    final nameEs = kDiseaseInfo[diseaseKey]?['nameEs'] ?? diseaseKey;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: color,
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameEs,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        scientificName,
                        style: TextStyle(
                          color: Colors.white.withAlpha(210),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.search,
                  label: 'Síntomas',
                  text: symptoms,
                  color: color,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.wb_cloudy_outlined,
                  label: 'Condiciones favorables',
                  text: conditions,
                  color: color,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.trending_down,
                  label: 'Impacto',
                  text: impact,
                  color: color,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.healing,
                  label: 'Tratamiento',
                  text: treatment,
                  color: color,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Costo aproximado',
                  text: costNote,
                  color: color,
                ),
                const SizedBox(height: 14),

                // ── Urgency badge ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: urgencyColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: urgencyColor.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: urgencyColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Urgencia: $urgencyLabel',
                          style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
