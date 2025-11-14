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
    _getCurrentLocation();
  }

  Future<void> _loadBusRoute() async {
    debugPrint("------------------- Iniciando carga de ruta -------------------");
    debugPrint("Polilínea recibida (raw): ${widget.polyline}");

    if (widget.polyline.isEmpty || widget.polyline == "[]") {
      debugPrint("Error: La cadena de polilínea está vacía o es un array vacío. No se dibujará la ruta.");
      // Considera mostrar un mensaje al usuario aquí.
      return; // Salir si no hay datos de polilínea
    }

    try {
      final List<dynamic> coords = json.decode(widget.polyline);
      debugPrint("JSON decodificado: $coords");

      if (coords.isEmpty) {
        debugPrint("Error: La lista de coordenadas decodificadas está vacía. No se dibujará la ruta.");
        return;
      }

      List<LatLng> routePoints = [];
      for (var p in coords) {
        if (p is Map<String, dynamic> && p.containsKey('lat') && p.containsKey('lng')) {
          routePoints.add(LatLng(p['lat'] as double, p['lng'] as double));
        } else {
          debugPrint("Advertencia: Punto con formato incorrecto encontrado: $p");
        }
      }

      debugPrint("Puntos de ruta generados (${routePoints.length} puntos): $routePoints");


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
            infoWindow: InfoWindow(title: 'Inicio de la ruta ${widget.routeNumber}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));
          _markers.add(Marker(
            markerId: const MarkerId('end'),
            position: routePoints.last,
            infoWindow: InfoWindow(title: 'Fin de la ruta ${widget.routeNumber}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));

          _center = routePoints.first;
          // Anima la cámara DESPUÉS de haber agregado los puntos a _polylines y definido _center.
          // mapController podría ser nulo aquí, es mejor animar en onMapCreated si los puntos ya están listos.
          // Si quieres animar aquí, descomenta y asegúrate de que mapController no sea nulo.
          // Future.delayed(const Duration(milliseconds: 500), () { // Pequeño retraso para asegurar que el mapa está listo
          //   mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13.5));
          // });
        });
        debugPrint("Polilínea y marcadores añadidos al estado.");

        // Si mapController ya está disponible (ej. si el mapa se renderiza antes que _loadBusRoute termine)
        // podríamos animar aquí, pero es más robusto hacerlo en onMapCreated.
        if (mapController != null) {
          mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13.5));
        }

      } else {
        debugPrint("La lista final de routePoints está vacía, no se añadirán polilíneas ni marcadores.");
      }
    } catch (e, stacktrace) {
      debugPrint("¡¡¡ERROR CRÍTICO!!! Fallo al cargar ruta o decodificar JSON: $e");
      debugPrint("StackTrace: $stacktrace");
      // Considera mostrar un mensaje de error al usuario.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar la ruta: $e')),
        );
      }
    }
    debugPrint("------------------- Fin carga de ruta -------------------");
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El servicio de ubicación está desactivado.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Los permisos de ubicación fueron denegados.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los permisos están denegados permanentemente. Por favor, habilítalos desde la configuración de la aplicación.')),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _center = LatLng(position.latitude, position.longitude);
      });

      mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (e) {
      debugPrint("Error al obtener la ubicación actual: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación actual: $e')),
        );
      }
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
              if (_polylines.isNotEmpty && _polylines.first.points.isNotEmpty) {
                mapController?.animateCamera(CameraUpdate.newLatLngZoom(_polylines.first.points.first, 13.5));
              } else {
                mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13.5));
              }
            },
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 13.5,
            ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ruta: ${widget.routeNumber} - ${widget.routeName}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Horario: ${widget.schedule}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
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