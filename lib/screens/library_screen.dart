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
            scientificName: 'Compsus sp. / Epicaerus sp. (Curculionidae)',
            symptoms: 'Perforaciones irregulares que atraviesan toda la lámina foliar '
                'con bordes necróticos cafés. Los adultos se alimentan de noche '
                'realizando cortes de tamaño variable en cualquier parte de la hoja.',
            conditions: 'Mayor incidencia en épocas secas y con estrés hídrico. '
                'El insecto se deja caer al suelo cuando se perturba la planta — '
                'comportamiento diagnóstico típico.',
            impact: 'Reducción del área fotosintética. En ataques severos puede '
                'causar defoliación parcial afectando la producción del siguiente ciclo.',
            treatment: 'Clorpirifos 480 EC (1.5 mL/litro) o Deltametrina 25 EC '
                '(0.5 mL/litro). Control cultural: sacudir ramas sobre bolsa plástica '
                'en horas de la mañana para recolectar adultos. '
                'Fuente: Manual del Cafetero Colombiano, Cenicafé.',
            urgencyLabel: 'MEDIA — tratar en 5 días',
            urgencyColor: Color(0xFF1565C0),
            costNote: 'COP 25,000–40,000 por litro de insecticida.',
            identificationText: 'El adulto mide 8–12 mm, cuerpo ovalado-robusto '
                'color café-dorado con patrón moteado de escamas. Tiene el rostro '
                'corto característico de los picudos (Curculionidae). Los élitros '
                'están fusionados — no puede volar. Se alimenta de noche; de día '
                'permanece inmóvil en las hojas o se deja caer al suelo si se '
                'perturba. Fuente: Cenicafé, Manual del Cafetero Colombiano (2013).',
            sourceNote: 'Fuente: Manual del Cafetero Colombiano, Cenicafé (2013), '
                'Vol. 2, pp. 261-306. DOI: 10.38141/cenbook-0026_25',
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
  final String? identificationText;
  final String? sourceNote;

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
    this.identificationText,
    this.sourceNote,
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

                // ── Cómo identificarlo (expandable, optional) ─────────
                if (identificationText != null) ...[
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: Icon(Icons.zoom_in, color: color, size: 20),
                      title: Text(
                        'Cómo identificarlo',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 28, right: 0, bottom: 8),
                          child: Text(
                            identificationText!,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Source citation (optional) ────────────────────────
                if (sourceNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    sourceNote!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
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
