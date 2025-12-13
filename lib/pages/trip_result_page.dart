import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
  // Coordenada por defecto (Cusco) por si falla todo
  LatLng _initialCenter = const LatLng(-13.53195, -71.967463);

  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final double _minSheetSize = 0.15;
  final double _maxSheetSize = 0.6;

  @override
  void initState() {
    super.initState();
    _processSegments();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<List<LatLng>> _getStreetRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          'http://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          return coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo ruta peatonal: $e");
    }
    return [start, end];
  }

  Future<void> _processSegments() async {
    Set<Polyline> newPolylines = {};
    Set<Marker> newMarkers = {};
    LatLng? startUserLocation; // Variable para guardar el inicio real

    if (widget.tripSegments.isEmpty) return;

    for (int i = 0; i < widget.tripSegments.length; i++) {
      final segment = widget.tripSegments[i];
      final String type = segment['type'] ?? 'walk';
      final String id = 'seg_$i';

      List<LatLng> rawPoints = [];
      try {
        if (segment['points'] is List<LatLng>) {
          rawPoints = segment['points'];
        } else if (segment['points'] is List) {
          rawPoints = List<LatLng>.from(segment['points']);
        }
      } catch (e) {
        continue;
      }

      if (rawPoints.isEmpty) continue;

      // 🔹 CAPTURAR UBICACIÓN DE INICIO (Primer punto del primer segmento)
      if (i == 0) {
        startUserLocation = rawPoints.first;
      }

      // LÓGICA DE DIBUJO
      List<LatLng> pointsToDraw = rawPoints;
      Color color;
      List<PatternItem> patterns = [];

      if (type == 'walk') {
        color = Colors.grey;
        patterns = [PatternItem.dot, PatternItem.gap(10)];
        if (rawPoints.length >= 2) {
          pointsToDraw = await _getStreetRoute(rawPoints.first, rawPoints.last);
        }
      } else {
        color = (segment['color'] is Color) ? segment['color'] : Colors.purple;
        patterns = [];
      }

      newPolylines.add(Polyline(
        polylineId: PolylineId(id),
        points: pointsToDraw,
        color: color,
        width: 5,
        patterns: patterns,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));

      // MARCADORES
      if (i == 0) {
        newMarkers.add(Marker(
          markerId: const MarkerId('origin'),
          position: rawPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(title: "Tu ubicación"),
        ));
      }

      if (type == 'bus') {
        newMarkers.add(Marker(
          markerId: MarkerId('board_$i'),
          position: rawPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: "Subir: ${segment['name'] ?? 'Bus'}"),
        ));
        newMarkers.add(Marker(
          markerId: MarkerId('alight_$i'),
          position: rawPoints.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: "Bajar: ${segment['name'] ?? 'Bus'}"),
        ));
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

    if (mounted) {
      setState(() {
        _polylines.addAll(newPolylines);
        _markers.addAll(newMarkers);
      });

      // 🔹 AQUÍ ESTÁ EL CAMBIO CLAVE:
      // Una vez que todo está cargado, movemos la cámara explícitamente
      if (startUserLocation != null && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(startUserLocation, 16.5), // Zoom cercano al usuario
        );
      }
    }
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
        subtitle = "Sigue la ruta punteada";
      } else if (isLast) {
        title = "Camina hacia tu destino";
        subtitle = "Estás llegando a ${widget.targetName ?? 'tu destino'}";
      } else {
        title = "Camina hacia el siguiente paradero";
        subtitle = "Transbordo a pie";
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
          GoogleMap(
            // La posición inicial es solo un placeholder hasta que _processSegments termine
            initialCameraPosition: CameraPosition(target: _initialCenter, zoom: 15),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (ctrl) {
              mapController = ctrl;
            },
            padding: const EdgeInsets.only(bottom: 160),
          ),

          DraggableScrollableSheet(
            controller: _sheetController,
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
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.tripSegments.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    }

                    if (index == widget.tripSegments.length + 1) {
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.red),
                        title: Text("Llegada a ${widget.targetName ?? 'Destino'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Has completado tu ruta."),
                      );
                    }

                    final dataIndex = index - 1;
                    final segment = widget.tripSegments[dataIndex];
                    final isLastSegment = dataIndex == widget.tripSegments.length - 1;

                    return _buildStepTile(segment, dataIndex, isLastSegment);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}