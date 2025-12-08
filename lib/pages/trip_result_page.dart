import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripResultPage extends StatefulWidget {
  final String routeName;
  final List<Map<String, dynamic>> tripSegments;
  final LatLng? targetLocation;
  final String? targetName;

  const TripResultPage({
    super.key,
    required this.routeName,
    required this.tripSegments,
    this.targetLocation,
    this.targetName,
  });

  @override
  State<TripResultPage> createState() => _TripResultPageState();
}

class _TripResultPageState extends State<TripResultPage> {
  GoogleMapController? mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  LatLng _initialCenter = const LatLng(-13.53195, -71.967463);

  // 1. CONTROLADOR PARA LA HOJA DESLIZANTE
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  // Constantes de tamaño para la hoja
  final double _minSheetSize = 0.15;
  final double _maxSheetSize = 0.6;

  @override
  void initState() {
    super.initState();
    _processSegments();
  }

  @override
  void dispose() {
    _sheetController.dispose(); // Limpiamos el controlador al salir
    super.dispose();
  }

  // Lógica para expandir/contraer con doble tap
  void _toggleSheet() {
    // Obtenemos el tamaño actual (entre 0.0 y 1.0)
    double currentSize = _sheetController.size;

    // Si está más cerca del mínimo, expandimos al máximo
    if (currentSize < (_maxSheetSize / 2)) {
      _sheetController.animateTo(
        _maxSheetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Si está expandido, lo contraemos al mínimo
      _sheetController.animateTo(
        _minSheetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _processSegments() {
    Set<Polyline> newPolylines = {};
    Set<Marker> newMarkers = {};

    for (int i = 0; i < widget.tripSegments.length; i++) {
      final segment = widget.tripSegments[i];
      final List<LatLng> points = List<LatLng>.from(segment['points']);
      final String type = segment['type'];
      final String id = 'seg_$i';

      Color color = Colors.grey;
      if (type == 'bus') {
        color = segment['color'] ?? Colors.purple;
      }

      newPolylines.add(Polyline(
        polylineId: PolylineId(id),
        points: points,
        color: color,
        width: 5,
        patterns: type == 'walk' ? [PatternItem.dot, PatternItem.gap(10)] : [],
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));

      if (points.isNotEmpty) {
        if (i == 0) {
          newMarkers.add(Marker(
            markerId: const MarkerId('origin'),
            position: points.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            infoWindow: const InfoWindow(title: "Tu ubicación"),
          ));
        }
        if (type == 'bus') {
          newMarkers.add(Marker(
            markerId: MarkerId('board_$i'),
            position: points.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: "Subir: ${segment['name']}"),
          ));
          newMarkers.add(Marker(
            markerId: MarkerId('alight_$i'),
            position: points.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: "Bajar: ${segment['name']}"),
          ));
        }
      }
    }

    if (widget.targetLocation != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('dest'),
        position: widget.targetLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.targetName ?? "Destino"),
      ));
    }

    if (widget.tripSegments.isNotEmpty) {
      final firstPoints = List<LatLng>.from(widget.tripSegments[0]['points']);
      if (firstPoints.isNotEmpty) {
        _initialCenter = firstPoints.first;
      }
    }

    setState(() {
      _polylines.addAll(newPolylines);
      _markers.addAll(newMarkers);
    });
  }

  Widget _buildStepTile(Map<String, dynamic> segment, int index, bool isLast) {
    String type = segment['type'];
    String title = "";
    String subtitle = "";
    IconData icon;
    Color color;

    if (type == 'walk') {
      icon = Icons.directions_walk;
      color = Colors.grey;
      if (index == 0) {
        title = "Camina hacia el paradero";
        subtitle = "Dirígete al punto de partida";
      } else if (isLast) {
        title = "Camina hacia tu destino";
        subtitle = "Estás llegando a ${widget.targetName ?? 'tu destino'}";
      } else {
        title = "Camina hacia el transbordo";
        subtitle = "Dirígete al siguiente paradero";
      }
    } else {
      icon = Icons.directions_bus;
      color = segment['color'] ?? Colors.purple;
      title = "Toma el bus ${segment['name']}";
      subtitle = "Sube y mantente en la ruta hasta el punto marcado";
    }

    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          if (!isLast && widget.tripSegments.length > 1)
            Container(height: 10, width: 2, color: Colors.grey[300])
        ],
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. MAPA
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _initialCenter, zoom: 15),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (ctrl) => mapController = ctrl,
            padding: const EdgeInsets.only(bottom: 160),
          ),

          // 2. MENÚ DESPLEGABLE
          DraggableScrollableSheet(
            controller: _sheetController, // Asignamos el controlador
            initialChildSize: 0.25,
            minChildSize: _minSheetSize,
            maxChildSize: _maxSheetSize,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))
                  ],
                ),
                child: Column(
                  children: [
                    // --- ZONA DE DOBLE TAP (HEADER) ---
                    GestureDetector(
                      onDoubleTap: _toggleSheet, // Aquí detectamos el doble tap
                      child: Container(
                        color: Colors.transparent, // Necesario para detectar toques en espacios vacíos
                        width: double.infinity,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            // Manija gris
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Título
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.timeline, color: Color(0xFF4A148C)),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Pasos para llegar (${widget.tripSegments.length} tramos)",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A148C)
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                      "(Doble tap)",
                                      style: TextStyle(fontSize: 10, color: Colors.grey)
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                    ),
                    // ----------------------------------

                    // Lista de instrucciones
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: widget.tripSegments.length + 1,
                        itemBuilder: (context, index) {
                          if (index == widget.tripSegments.length) {
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.red),
                              title: Text("Llegada a ${widget.targetName ?? 'Destino'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text("Has completado tu ruta."),
                            );
                          }
                          final segment = widget.tripSegments[index];
                          final isLastSegment = index == widget.tripSegments.length - 1;

                          return _buildStepTile(segment, index, isLastSegment);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}