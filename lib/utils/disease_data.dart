import 'package:flutter/material.dart';

// ── Disease class labels — order matches ONNX output columns 4-7 ─────────────
// YOLOv8 output: [1, 8, 8400]  cols 4=Roya 5=Coco 6=Sano 7=Minador
const List<String> kDiseaseLabels = [
  'roya',
  'coco',
  'sano',
  'minador',
];

// ── Human-readable info per class ─────────────────────────────────────────────
const Map<String, Map<String, String>> kDiseaseInfo = {
  'sano': {
    'nameEs': 'Planta Sana',
    'description':
        'La planta no presenta síntomas de enfermedad. Las hojas muestran un color verde uniforme y un aspecto saludable.',
    'symptoms': 'Sin síntomas visibles. Follaje verde brillante y uniforme.',
    'treatment':
        'Continuar con el manejo preventivo: fertilización balanceada, riego adecuado y monitoreo periódico.',
    'severity': 'none',
  },
  'roya': {
    'nameEs': 'Roya del Cafeto',
    'description':
        'Enfermedad fúngica causada por Hemileia vastatrix. Es la enfermedad más devastadora del café a nivel mundial.',
    'symptoms':
        'Manchas amarillas en el haz de la hoja que evolucionan a pústulas anaranjadas en el envés. Las hojas afectadas caen prematuramente.',
    'treatment':
        'Aplicar fungicidas a base de cobre o triazoles. Usar variedades resistentes (Castillo, Colombia). Manejo cultural: poda y regulación de sombra.',
    'severity': 'high',
  },
  'coco': {
    'nameEs': 'Cochinilla',
    'description':
        'Infestación por cochinillas (Coccinellidae) que se adhieren al tallo, ramas y hojas del cafeto chupando la savia. Producen melaza que favorece la aparición de fumagina.',
    'symptoms':
        'Masas algodonosas o cerosas blancas en tallos, ramas y hojas. Amarillamiento y caída prematura de hojas. Presencia de fumagina (hollín negro) sobre las partes afectadas.',
    'treatment':
        'Imidacloprid 350 SC (0.5 ml/litro) aplicado al suelo o follaje. Control biológico con Cryptolaemus montrouzieri. Lavado con solución jabonosa en focos iniciales.',
    'severity': 'medium',
  },
  'minador': {
    'nameEs': 'Minador de la Hoja',
    'description':
        'Daño causado por la larva de Leucoptera coffeella. El insecto excava galerías dentro del tejido foliar consumiendo el mesófilo.',
    'symptoms':
        'Manchas translúcidas de aspecto blanco-amarillento en las hojas. Al trasluz se observan galerías irregulares con larvas o pupas en su interior.',
    'treatment':
        'Control biológico con parasitoides (Mirax insularis). Regular la sombra. Aplicar insecticidas sistémicos como imidacloprid en focos de alta infestación.',
    'severity': 'medium',
  },
};

Color diseaseColor(String disease) {
  switch (disease) {
    case 'sano':
      return const Color(0xFF2E7D32);
    case 'roya':
      return const Color(0xFFE65100);
    case 'coco':
      return const Color(0xFF1565C0);
    case 'minador':
      return const Color(0xFF6A1B9A);
    default:
      return const Color(0xFF607D8B);
  }
}

IconData diseaseIcon(String disease) {
  switch (disease) {
    case 'sano':
      return Icons.check_circle;
    case 'roya':
      return Icons.warning_amber;
    case 'coco':
      return Icons.bug_report;
    case 'minador':
      return Icons.pest_control;
    default:
      return Icons.help_outline;
  }
}

String severityLabel(String severity) {
  switch (severity) {
    case 'none':
      return 'Sin riesgo';
    case 'low':
      return 'Riesgo bajo';
    case 'medium':
      return 'Riesgo medio';
    case 'high':
      return 'Riesgo alto';
    default:
      return 'Desconocido';
  }
}

Color severityColor(String severity) {
  switch (severity) {
    case 'none':
      return const Color(0xFF2E7D32);
    case 'low':
      return const Color(0xFF558B2F);
    case 'medium':
      return const Color(0xFFF57F17);
    case 'high':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF607D8B);
  }
}
