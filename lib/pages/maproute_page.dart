import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final String routeName;
  final String routeNumber;
  final String schedule;
  final String polyline;
  final LatLng? targetLocation;
  final String? targetName;

  const MapPage({
    super.key,
    required this.routeName,
    required this.routeNumber,
    required this.schedule,
    required this.polyline,
    this.targetLocation,
    this.targetName,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusRoute();
      _getCurrentLocation();
    });
  }

  Future<void> _loadBusRoute() async {
    if (widget.polyline.isEmpty || widget.polyline == "[]") return;

    try {
      final List<dynamic> coords = json.decode(widget.polyline);
      if (coords.isEmpty) return;

      List<LatLng> routePoints = [];
      for (var p in coords) {
        if (p is Map<String, dynamic> && p.containsKey('lat') && p.containsKey('lng')) {
          routePoints.add(LatLng(p['lat'] as double, p['lng'] as double));
        }
      }

      if (routePoints.isNotEmpty) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('busRoute'),
              points: routePoints,
              color: Colors.purple,
              width: 6,
            ),
          );

          _markers.add(Marker(
            markerId: const MarkerId('start'),
            position: routePoints.first,
            infoWindow: InfoWindow(title: 'Inicio: ${widget.routeNumber}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));
          _markers.add(Marker(
            markerId: const MarkerId('end'),
            position: routePoints.last,
            infoWindow: InfoWindow(title: 'Fin: ${widget.routeNumber}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));

          if (widget.targetLocation != null) {
            _markers.add(Marker(
              markerId: const MarkerId('user_target'),
              position: widget.targetLocation!,
              infoWindow: InfoWindow(title: widget.targetName ?? 'Mi Destino'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ));
          }

          _center = routePoints.first;
        });

        if (mapController != null) {
          mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13.5));
        }
      }
    } catch (e) {
      debugPrint("Error loading route: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _center = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Error GPS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routeNumber} - ${widget.routeName}'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
              if (_polylines.isNotEmpty) {
                mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13.5));
              }
            },
            initialCameraPosition: CameraPosition(target: _center, zoom: 13.5),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            bottom: 120,
            right: 15,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ruta: ${widget.routeNumber} - ${widget.routeName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Horario: ${widget.schedule}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  if (widget.targetName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Destino marcado: ${widget.targetName}',
                          style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold)),
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