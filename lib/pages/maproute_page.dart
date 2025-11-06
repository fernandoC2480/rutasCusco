import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final String routeName;
  final String routeNumber;
  final String schedule;
  final String polyline;

  const MapPage({
    super.key,
    required this.routeName,
    required this.routeNumber,
    required this.schedule,
    required this.polyline,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(-13.53195, -71.967463);
  Position? _currentPosition;

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadBusRoute();
  }

  Future<void> _loadBusRoute() async {
    try {
      final List<dynamic> coords = json.decode(widget.polyline);
      List<LatLng> routePoints = coords
          .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
          .toList();

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('busRoute'),
            points: routePoints,
            color: Colors.purple,
            width: 6,
          ),
        );

        if (routePoints.isNotEmpty) {
          _markers.add(Marker(
            markerId: const MarkerId('start'),
            position: routePoints.first,
            infoWindow: const InfoWindow(title: 'Inicio de la ruta'),
          ));
          _markers.add(Marker(
            markerId: const MarkerId('end'),
            position: routePoints.last,
            infoWindow: const InfoWindow(title: 'Fin de la ruta'),
          ));
          _center = routePoints.first;
        }
      });
    } catch (e) {
      debugPrint("Error al cargar ruta: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('El servicio de ubicación está desactivado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Los permisos están denegados permanentemente.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _center = LatLng(position.latitude, position.longitude);
    });

    mapController?.animateCamera(CameraUpdate.newLatLng(_center));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 13.5,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
          ),

          // 🔹 Nombre de la ruta centrado arriba
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A148C).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.routeNumber} - ${widget.routeName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Información inferior
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ruta: ${widget.routeNumber}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text('Horario: ${widget.schedule}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('📍 Ver mi ubicación'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
