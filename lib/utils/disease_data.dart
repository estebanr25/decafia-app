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
  'model_unavailable': {
    'nameEs': 'Error de análisis',
    'description': 'El modelo no pudo procesar la imagen.',
    'symptoms': '',
    'treatment': 'Reinstala la aplicación o contacta al equipo de DECAFIA.',
    'severity': 'none',
  },
  'no_detection': {
    'nameEs': 'Sin síntomas detectados',
    'description':
        'El modelo no encontró ninguna clase por encima del umbral de confianza. '
        'Esto puede indicar que la hoja está sana o que la imagen no tiene suficiente calidad.',
    'symptoms': 'No se observaron síntomas con confianza suficiente.',
    'treatment':
        'Toma otra foto con mejor iluminación y enfoque, o revisa otras hojas de la planta.',
    'severity': 'none',
  },
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
    'nameEs': 'Coco (Vaquita)',
    'scientificName': 'Compsus sp. / Epicaerus sp. (Curculionidae)',
    'description': 'El Coco o Vaquita es un picudo masticador '
        '(familia Curculionidae, géneros Compsus sp. o Epicaerus sp.) '
        'documentado por Cenicafé como plaga del follaje del cafeto '
        'en la zona cafetera colombiana. Los adultos realizan '
        'perforaciones irregulares en el limbo foliar.',
    'symptoms': 'Perforaciones irregulares que atraviesan toda la '
        'lámina foliar, con bordes necróticos cafés. Cortes de tamaño '
        'variable en cualquier parte de la hoja. En ataques severos '
        'produce defoliación parcial de la planta.',
    'conditions': 'Mayor incidencia en épocas secas y en plantas '
        'con estrés hídrico. Los adultos se alimentan de noche y '
        'se dejan caer al suelo cuando se perturba la planta.',
    'impact': 'Reducción del área fotosintética y del vigor de '
        'la planta. Puede causar defoliación parcial en ataques '
        'severos, afectando la producción del siguiente ciclo.',
    'treatment': 'Clorpirifos 480 EC (1.5 mL/litro) o Deltametrina '
        '25 EC (0.5 mL/litro). Aplicar en horas frescas. '
        'Control cultural: recolección manual de adultos en horas '
        'de la mañana sacudiendo las ramas sobre una bolsa plástica.',
    'source': 'Manual del Cafetero Colombiano, Cenicafé (2013), '
        'Vol. 2, pp. 261-306. DOI: 10.38141/cenbook-0026_25',
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
    case 'no_detection':
      return const Color(0xFF78909C); // blue-grey, distinct from all classes
    case 'model_unavailable':
      return const Color(0xFFB71C1C); // deep red
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
    case 'no_detection':
      return Icons.search_off_rounded;
    case 'model_unavailable':
      return Icons.error_outline_rounded;
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
