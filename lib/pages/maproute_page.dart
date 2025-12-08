import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final String routeName;
  final String routeNumber;
  final String schedule;

  // Mantenemos este para que main.dart NO de error
  final String polyline;

  // Agregamos este opcional para recibir Ida y Vuelta
  final List<String>? polylinesList;

  const MapPage({
    super.key,
    required this.routeName,
    required this.routeNumber,
    required this.schedule,
    required this.polyline, // Requerido por main.dart
    this.polylinesList,     // Opcional para la nueva lógica
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(-13.53195, -71.967463);
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadBusRoutes();
  }

  void _loadBusRoutes() {
    // 1. Determinamos qué fuente de datos usar
    List<String> routesToDraw = [];

    if (widget.polylinesList != null && widget.polylinesList!.isNotEmpty) {
      // Si venimos de la lista agrupada (Ida/Vuelta)
      routesToDraw = widget.polylinesList!;
    } else if (widget.polyline.isNotEmpty && widget.polyline != "[]") {
      // Si venimos de una llamada simple (compatibilidad)
      routesToDraw = [widget.polyline];
    } else {
      return; // Nada que dibujar
    }

    Set<Polyline> newPolylines = {};
    Set<Marker> newMarkers = {};
    LatLng? firstPoint;

    // Colores: Morado (Ida), Turquesa (Vuelta)
    List<Color> colors = [Colors.purple, Colors.teal];

    for (int i = 0; i < routesToDraw.length; i++) {
      String polylineStr = routesToDraw[i];

      try {
        final List<dynamic> coords = json.decode(polylineStr);
        List<LatLng> routePoints = [];
        for (var p in coords) {
          if (p['lat'] != null && p['lng'] != null) {
            routePoints.add(LatLng(p['lat'], p['lng']));
          }
        }

        if (routePoints.isNotEmpty) {
          Color routeColor = colors[i % colors.length];
          String label = (routesToDraw.length > 1)
              ? (i == 0 ? "Ida" : "Vuelta")
              : "";

          // Polilínea
          newPolylines.add(Polyline(
            polylineId: PolylineId('route_$i'),
            points: routePoints,
            color: routeColor,
            width: 5,
            jointType: JointType.round,
          ));

          // Marcadores
          newMarkers.add(Marker(
            markerId: MarkerId('start_$i'),
            position: routePoints.first,
            infoWindow: InfoWindow(title: 'Inicio $label'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));

          newMarkers.add(Marker(
            markerId: MarkerId('end_$i'),
            position: routePoints.last,
            infoWindow: InfoWindow(title: 'Fin $label'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));

          if (i == 0) firstPoint = routePoints.first;
        }
      } catch (e) {
        debugPrint("Error decodificando ruta: $e");
      }
    }

    setState(() {
      _polylines.addAll(newPolylines);
      _markers.addAll(newMarkers);
      if (firstPoint != null) {
        _center = firstPoint;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showLegend = (widget.polylinesList != null && widget.polylinesList!.length > 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routeNumber} - ${widget.routeName}'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 13.0),
            onMapCreated: (ctrl) => mapController = ctrl,
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Leyenda (Solo si hay Ida y Vuelta)
          if (showLegend)
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Leyenda", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Row(children: [Icon(Icons.horizontal_rule, color: Colors.purple), SizedBox(width: 5), Text("Ida")]),
                    Row(children: [Icon(Icons.horizontal_rule, color: Colors.teal), SizedBox(width: 5), Text("Vuelta")]),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 20, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ruta: ${widget.routeName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Horario: ${widget.schedule}"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}