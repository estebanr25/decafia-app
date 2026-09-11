import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/diagnosis.dart';
import '../providers/diagnosis_provider.dart';
import '../services/location_service.dart';
import '../utils/disease_data.dart';
import 'result_screen.dart';

// Colombia center — shown on first load before any diagnosis markers
const LatLng _kDefaultCenter = LatLng(4.5709, -74.2973);
const double _kDefaultZoom = 6;
const double _kDiagnosisZoom = 12;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _loadingPosition = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentPosition());
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _loadCurrentPosition() async {
    if (_loadingPosition) return;
    setState(() => _loadingPosition = true);

    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (pos == null) {
      setState(() => _loadingPosition = false);
      final denied = !(await LocationService.hasPermission());
      if (denied && mounted) {
        final permanent = await Geolocator.checkPermission() ==
            LocationPermission.deniedForever;
        _showPermissionDialog(permanent: permanent);
      }
      return;
    }

    setState(() {
      _loadingPosition = false;
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  void _centerOnMe() async {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 14);
      return;
    }
    await _loadCurrentPosition();
    if (_currentPosition != null && mounted) {
      _mapController.move(_currentPosition!, 14);
    }
  }

  void _showPermissionDialog({required bool permanent}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_off, size: 40, color: Colors.orange),
        title: const Text('Permiso de ubicación'),
        content: Text(
          permanent
              ? 'El acceso a la ubicación fue denegado permanentemente. '
                  'Ve a Ajustes del teléfono → Aplicaciones → DECAFIA → Permisos '
                  'y activa la ubicación para ver tu posición en el mapa.'
              : 'DECAFIA necesita acceso a tu ubicación para:\n'
                  '• Mostrar tu posición en el mapa\n'
                  '• Geolocalizar los diagnósticos\n\n'
                  'Sin este permiso el mapa usará la ubicación predeterminada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          if (permanent)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Abrir ajustes'),
            )
          else
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _loadCurrentPosition();
              },
              child: const Text('Permitir'),
            ),
        ],
      ),
    );
  }

  // ── Map fit ────────────────────────────────────────────────────────────────

  void _fitBounds(List<Diagnosis> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude!;
    double maxLat = points.first.latitude!;
    double minLng = points.first.longitude!;
    double maxLng = points.first.longitude!;
    for (final d in points) {
      if (d.latitude! < minLat) minLat = d.latitude!;
      if (d.latitude! > maxLat) maxLat = d.latitude!;
      if (d.longitude! < minLng) minLng = d.longitude!;
      if (d.longitude! > maxLng) maxLng = d.longitude!;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showDiagnosisSheet(BuildContext context, Diagnosis d) {
    final info = kDiseaseInfo[d.disease];
    final color = diseaseColor(d.disease);
    final name = info?['nameEs'] ?? d.disease;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(diseaseIcon(d.disease), color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
                Text('${(d.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${d.latitude!.toStringAsFixed(5)}, '
              '${d.longitude!.toStringAsFixed(5)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ResultScreen(diagnosis: d)),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white),
                child: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final withLocation = provider.historyWithLocation;

    // Determine initial map center: first diagnosis marker, or current GPS,
    // or default El Socorro
    final initialCenter = withLocation.isNotEmpty
        ? LatLng(withLocation.first.latitude!, withLocation.first.longitude!)
        : _currentPosition ?? _kDefaultCenter;
    final initialZoom =
        withLocation.isNotEmpty ? _kDiagnosisZoom : _kDefaultZoom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          if (withLocation.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.fit_screen),
              tooltip: 'Ajustar vista',
              onPressed: () => _fitBounds(withLocation),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.decafia.app',
              ),

              // ── Blue dot — current GPS position ────────────────────
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1976D2).withAlpha(120),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // ── Diagnosis markers ──────────────────────────────────
              MarkerLayer(
                markers: withLocation.map((d) {
                  final color = diseaseColor(d.disease);
                  return Marker(
                    point: LatLng(d.latitude!, d.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showDiagnosisSheet(context, d),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(120),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          diseaseIcon(d.disease),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Empty state overlay ────────────────────────────────────
          if (withLocation.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Sin diagnósticos con ubicación',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Activa el GPS al realizar diagnósticos\n'
                      'para ver los puntos en el mapa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // ── Legend ────────────────────────────────────────────────
          Positioned(
            bottom: 80,
            left: 12,
            child: _Legend(
              noLocationCount: provider.noLocationCount,
            ),
          ),

          // ── Loading indicator ──────────────────────────────────────
          if (_loadingPosition)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Obteniendo ubicación...',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // ── "Mi ubicación" FAB ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnMe,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        tooltip: 'Mi ubicación',
        child: _loadingPosition
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final int noLocationCount;

  const _Legend({required this.noLocationCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...kDiseaseInfo.entries
                .where((e) => kDiseaseLabels.contains(e.key))
                .map((e) {
              final color = diseaseColor(e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(e.value['nameEs']!,
                      style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 2),
                ],
              );
            }),
            if (noLocationCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$noLocationCount sin ubicación GPS',
                style: TextStyle(
                    fontSize: 9, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
