import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'maproute_page.dart';
import 'routes_page.dart';

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  // Datos y Estado
  List<Map<String, dynamic>> allRoutes = [];
  List<Map<String, dynamic>> validRoutes = [];

  bool _isLoading = true;
  bool _hasInternet = true; // Variable para controlar el estado de red

  LatLng _targetLocation = const LatLng(-13.53195, -71.967463);
  Position? _userPosition;
  Set<Marker> _markers = {};
  String _statusMessage = "Cargando datos...";

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndInit();
  }

  // 1. Verificación de Conexión + Inicialización
  Future<void> _checkConnectivityAndInit() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Tienes internet, cargamos todo normal
        setState(() => _hasInternet = true);
        await _loadRoutesData();
        await _getUserLocation();
      }
    } catch (_) {
      // No hay internet
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRoutesData() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final jsonPaths = manifestMap.keys
          .where((path) => path.startsWith('assets/json/') && path.endsWith('.json'))
          .toList();

      List<Map<String, dynamic>> routes = [];
      for (final path in jsonPaths) {
        final jsonStr = await rootBundle.loadString(path);
        final data = json.decode(jsonStr);
        final List<dynamic> points = data['points'] ?? [];

        routes.add({
          'name': data['name'],
          'number': data['number'],
          'schedule': data['schedule'],
          'points_data': points,
          'polyline': json.encode(points),
        });
      }

      setState(() {
        allRoutes = routes;
        _isLoading = false;
        _statusMessage = "Selecciona un destino en el mapa";
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  Future<void> _getUserLocation() async {
    // Verificación básica de permisos (simplificada para este ejemplo)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = position;
    });
  }

  // --- Lógica del Mapa (Búsqueda y Filtro) ---
  Future<void> _searchLocationFromText() async {
    final query = _searchController.text;
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();

    try {
      List<Location> locations = await locationFromAddress("$query, Cusco");
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        _updateTargetAndFilter(target, query);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lugar no encontrado")));
    }
  }

  void _onMapTap(LatLng point) async {
    _updateTargetAndFilter(point, "Destino seleccionado");
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;
        String address = place.thoroughfare ?? place.name ?? "Destino";
        setState(() {
          _searchController.text = address;
          _markers = {
            Marker(markerId: const MarkerId('target'), position: point, infoWindow: InfoWindow(title: address))
          };
        });
      }
    } catch (_) {}
  }

  void _updateTargetAndFilter(LatLng target, String title) {
    setState(() {
      _targetLocation = target;
      _markers = {
        Marker(
          markerId: const MarkerId('target'),
          position: target,
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        )
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    _filterRoutesConnectingUserAndTarget(target);
  }

  void _filterRoutesConnectingUserAndTarget(LatLng target) {
    if (_userPosition == null) {
      _getUserLocation();
      setState(() => _statusMessage = "Esperando señal GPS...");
      return;
    }

    List<Map<String, dynamic>> matches = [];
    const double radius = 600;

    for (var route in allRoutes) {
      List<dynamic> points = route['points_data'];
      bool nearUser = false;
      bool nearTarget = false;

      for (int i = 0; i < points.length; i += 3) {
        var p = points[i];
        double lat = p['lat'];
        double lng = p['lng'];

        if (!nearUser) {
          if (Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, lat, lng) < radius) nearUser = true;
        }
        if (!nearTarget) {
          if (Geolocator.distanceBetween(target.latitude, target.longitude, lat, lng) < radius) nearTarget = true;
        }
        if (nearUser && nearTarget) {
          matches.add(route);
          break;
        }
      }
    }

    setState(() {
      validRoutes = matches;
      if (matches.isEmpty) _statusMessage = "No hay rutas directas entre tú y el destino.";
    });
  }

  // Acción del botón flotante personalizado
  void _goToMyLocation() {
    if (_userPosition != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
      ));
    } else {
      _getUserLocation();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Obteniendo ubicación...")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return Scaffold(
        backgroundColor: const Color(0xFF4A148C),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 80, color: Colors.white54),
                const SizedBox(height: 20),
                const Text(
                  "No hay conexión a internet",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "El mapa requiere internet para funcionar. Puesdes buscar manualmente las rutas de los buses.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text("Lista de Rutas"),
                            backgroundColor: const Color(0xFF4A148C),
                            foregroundColor: Colors.white,
                          ),
                          body: const RoutesSearchPage(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list, color: Color(0xFF4A148C)),
                  label: const Text("VER LAS RUTAS DE LOS BUSES", style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _checkConnectivityAndInit,
                  child: const Text("Reintentar conexión", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }

    // Pantalla de Carga
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 3. Pantalla del Mapa (Conexión OK)
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _targetLocation, zoom: 14.5),
            onMapCreated: (ctrl) => _mapController = ctrl,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // 🔴 Desactivamos el botón original (arriba)
            zoomControlsEnabled: false,
            onTap: _onMapTap,
            padding: const EdgeInsets.only(bottom: 120),
          ),

          // Barra de Búsqueda
          Positioned(
            top: 40, left: 15, right: 15,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Toca el mapa o escribe destino',
                  prefixIcon: const Icon(Icons.place, color: Color(0xFF4A148C)),
                  suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _searchLocationFromText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                onSubmitted: (_) => _searchLocationFromText(),
              ),
            ),
          ),

          // 🔴 Botón de Ubicación Personalizado (Posicionado Abajo)
          Positioned(
            bottom: 240, // Altura calculada para que no lo tape la lista (ajustable)
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              backgroundColor: const Color(0xFF4A148C), // Color Morado de la App
              foregroundColor: Colors.white,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Lista de Resultados
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (ctx, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(width: 40, height: 5, color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          const Text("Rutas Sugeridas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_userPosition == null)
                            const Text("(GPS no detectado)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: validRoutes.isEmpty
                          ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                          : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: validRoutes.length,
                        itemBuilder: (ctx, i) {
                          final r = validRoutes[i];
                          return ListTile(
                            leading: const Icon(Icons.directions_bus, color: Color(0xFF4A148C)),
                            title: Text(r['number']),
                            subtitle: const Text("Conecta tu ubicación con el destino"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => MapPage(
                                    routeName: r['name'],
                                    routeNumber: r['number'],
                                    schedule: r['schedule'],
                                    polyline: r['polyline'],
                                  )
                              ));
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}