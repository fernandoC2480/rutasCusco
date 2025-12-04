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

  List<Map<String, dynamic>> allRoutes = [];
  List<Map<String, dynamic>> validRoutes = [];

  List<String> _suggestions = [];
  bool _showSuggestionsList = false;

  final List<String> _cuscoPlaces = [
    "Plaza de Armas del Cusco", "Qorikancha", "Sacsayhuamán", "Barrio de San Blas", "Mercado de San Pedro", "Real Plaza Cusco", "Avenida El Sol", "Centro Histórico del Cusco", "Calle Hatun Rumiyoc", "Piedra de los 12 Ángulos",
    "Templo de la Compañía de Jesús", "Catedral del Cusco", "Plaza San Francisco", "Iglesia de San Cristóbal", "Mirador de San Blas",
    "Mirador del Cristo Blanco", "Calle Loreto", "Museo Inka", "Museo de Arte Precolombino", "ChocoMuseo Cusco",
    "Plazoleta Regocijo", "Parque Orellana Pumaqchupan", "Centro Qosqo de Arte Nativo", "Estación Wanchaq", "Estación San Pedro",
    "Av. de la Cultura", "Terminal Terrestre de Cusco", "Templo de Santo Domingo", "Plazoleta Espinar", "Templo de San Blas",
    "Corredor Turístico del Cusco", "Rumi Punku", "Plaza Tupac Amaru", "Planetarium Cusco", "Calle Mantas",
    "Plaza Regocijo (Plaza Kusipata)", "Museo Histórico Regional", "Museo Casa Concha", "Mercado de Ttio", "Mercado de Wanchaq",
    "Parque Zonal Pachacútec", "Convento de Santa Catalina", "Iglesia de La Merced", "Av. Collasuyo", "Parque Quillabamba (Cusco)",
    "Parque Perayoc", "Centro Comercial Mall Aventura Cusco", "Jardín Sagrado", "Complejo Qenqo", "RENIEC Cusco", "SUNARP Cusco", "SUNAT Cusco",
    "Municipalidad Provincial del Cusco", "Gobierno Regional del Cusco",
    "Poder Judicial del Cusco", "Ministerio Público – Fiscalía Cusco",
    "Essalud Cusco – Oficina Central", "Dirección Regional de Transportes y Comunicaciones DRTC",
    "Dirección Regional de Educación del Cusco DREC", "Oficina de Migraciones Cusco",
    "Policía Nacional del Perú – Macro Región Policial Cusco",
    "Serfor Cusco", "Dirección Regional de Salud DIRESA Cusco", "Hospital Regional del Cusco", "Hospital Antonio Lorena", "Hospital Adolfo Guevara Velasco (Essalud)",
    "Hospital de Contingencia Lorena", "Hospital de Wanchaq",
    "Centro de Salud San Sebastián", "Clínica Pardo", "Clínica MacSalud",
    "Clínica San Juan de Dios Cusco", "Clínica Peruano Suiza", "Clínica Vesalio Cusco", "Comisaría PNP Cusco",
    "Comisaría PNP San Sebastián",
    "Comisaría PNP San Jerónimo",
    "Comisaría PNP Santiago",
    "Comisaría PNP Wanchaq",
    "Comisaría PNP Tahuantinsuyo",
    "Comisaría PNP Zarzuela (Sector Industrial)",
    "Comisaría PNP Viva el Perú",
    "Comisaría PNP Independencia",
    "Comisaría PNP Pisac (zona cercana con alta afluencia)",
    "Comisaría PNP Poroy", "Universidad Nacional San Antonio Abad del Cusco (UNSAAC)",
    "Universidad Andina del Cusco (UAC)",
    "Universidad Continental – Filial Cusco"
  ];

  bool _isLoading = true;
  bool _hasInternet = true;
  bool _showResults = false;

  LatLng _targetLocation = const LatLng(-13.53195, -71.967463);
  Position? _userPosition;
  Set<Marker> _markers = {};
  String _statusMessage = "Cargando datos...";

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndInit();
  }

  Future<void> _checkConnectivityAndInit() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() => _hasInternet = true);
        await _loadRoutesData();
        await _getUserLocation();
      }
    } catch (_) {
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getUserLocation() async {
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

  void _onSearchTextChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _showSuggestionsList = false;
        _suggestions = [];
      });
      return;
    }

    final matches = _cuscoPlaces.where((place) {
      return place.toLowerCase().contains(text.toLowerCase());
    }).toList();

    setState(() {
      _suggestions = matches;
      _showSuggestionsList = matches.isNotEmpty;
    });
  }

  Future<void> _searchLocationFromText(String query) async {
    if (query.isEmpty) return;
    setState(() => _showSuggestionsList = false);
    FocusScope.of(context).unfocus();

    try {
      List<Location> locations = await locationFromAddress("$query, Cusco");
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        _updateTargetAndFilter(target, query);
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se encontró esa ubicación exacta.")));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lugar no encontrado (Intenta ser más específico)")));
    }
  }

  void _onMapTap(LatLng point) async {
    setState(() => _showSuggestionsList = false);
    FocusScope.of(context).unfocus();

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
      _showResults = true;
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
    const double radius = 350;

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
                const Text("No hay conexión a internet", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text("El mapa requiere internet para funcionar.", style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(appBar: AppBar(title: const Text("Lista de Rutas"), backgroundColor: const Color(0xFF4A148C), foregroundColor: Colors.white), body: const RoutesSearchPage())));
                  },
                  icon: const Icon(Icons.list, color: Color(0xFF4A148C)),
                  label: const Text("VER LAS RUTAS DE LOS BUSES", style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                ),
                const SizedBox(height: 20),
                TextButton(onPressed: _checkConnectivityAndInit, child: const Text("Reintentar conexión", style: TextStyle(color: Colors.white)))
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _targetLocation, zoom: 14.5),
            onMapCreated: (ctrl) => _mapController = ctrl,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: _onMapTap,
            padding: EdgeInsets.only(bottom: _showResults ? 240 : 20),
          ),

          Positioned(
            top: 40, left: 15, right: 15,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: _showSuggestionsList
                          ? const BorderRadius.vertical(top: Radius.circular(20))
                          : BorderRadius.circular(30)
                  ),
                  margin: EdgeInsets.zero,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchTextChanged,
                    decoration: InputDecoration(
                      hintText: 'Toca el mapa o escribe destino',
                      prefixIcon: const Icon(Icons.place, color: Color(0xFF4A148C)),
                      suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _searchLocationFromText(_searchController.text)
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    onSubmitted: (val) => _searchLocationFromText(val),
                  ),
                ),

                if (_showSuggestionsList)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))]
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_suggestions[index]),
                          leading: const Icon(Icons.history, size: 20, color: Colors.grey),
                          onTap: () {
                            _searchController.text = _suggestions[index];
                            _searchLocationFromText(_suggestions[index]);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            bottom: _showResults ? 240 : 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
              child: const Icon(Icons.my_location),
            ),
          ),

          if (_showResults)
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
                                      targetLocation: _targetLocation,
                                      targetName: _searchController.text.isNotEmpty
                                          ? _searchController.text
                                          : "Destino seleccionado",
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