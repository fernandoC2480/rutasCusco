import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_stats_service.dart';
import '../services/favorites_service.dart'; // Asegúrate de importar esto
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'trip_result_page.dart';
import 'routes_page.dart';

class MapSearchPage extends StatefulWidget {
  final LatLng? initialTarget;
  final String? initialName;

  const MapSearchPage({
    super.key,
    this.initialTarget,
    this.initialName,
  });

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FavoritesService _favoritesService = FavoritesService(); // Servicio de favoritos
  GoogleMapController? _mapController;

  List<Map<String, dynamic>> allRoutes = [];
  List<Map<String, dynamic>> searchResults = [];

  List<String> _suggestions = [];
  bool _showSuggestionsList = false;
  final List<String> _cuscoPlaces = ["Plaza de Armas del Cusco", "Real Plaza Cusco", "Terminal Terrestre Cusco", "Mercado San Pedro", "Mercado Wanchaq", "UNSAAC", "Av. La Cultura", "Av. El Sol", "Mall Aventura Cusco"];

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

    // Listener para sugerencias
    _searchController.addListener(() {
      // ... tu lógica de listener si la tenías ...
    });
  }

  Future<void> _checkConnectivityAndInit() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() => _hasInternet = true);
        await _loadRoutesData();
        await _getUserLocation();

        if (widget.initialTarget != null && mounted) {
          _updateTargetAndFilter(widget.initialTarget!, widget.initialName ?? "Ubicación");
          _searchController.text = widget.initialName ?? "";
        }
      }
    } catch (_) {
      if (mounted) setState(() { _hasInternet = false; _isLoading = false; });
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

        List<LatLng> decodedPoints = [];
        for(var p in points) {
          if(p['lat'] != null && p['lng'] != null) {
            decodedPoints.add(LatLng(p['lat'], p['lng']));
          }
        }

        routes.add({
          'name': data['name'],
          'number': data['number'],
          'schedule': data['schedule'],
          'points_raw': decodedPoints,
        });
      }

      if (mounted) {
        setState(() {
          allRoutes = routes;
          _isLoading = false;
          _statusMessage = "Selecciona un destino en el mapa";
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
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
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _userPosition = position);
    } catch (_) {}
  }

  void _onSearchTextChanged(String text) {
    if (text.isEmpty) { setState(() { _showSuggestionsList = false; _suggestions = []; }); return; }
    final matches = _cuscoPlaces.where((place) => place.toLowerCase().contains(text.toLowerCase())).toList();
    setState(() { _suggestions = matches; _showSuggestionsList = matches.isNotEmpty; });
  }

  Future<void> _searchLocationFromText(String query) async {
    if (query.isEmpty) return;
    setState(() => _showSuggestionsList = false);
    FocusScope.of(context).unfocus();
    try {
      List<Location> locations = await locationFromAddress("$query, Cusco");
      if (locations.isNotEmpty) {
        final loc = locations.first;
        _updateTargetAndFilter(LatLng(loc.latitude, loc.longitude), query);
      }
    } catch (_) {}
  }

  void _onMapTap(LatLng point) {
    setState(() => _showSuggestionsList = false);
    FocusScope.of(context).unfocus();
    _updateTargetAndFilter(point, "Destino seleccionado");
  }

  void _updateTargetAndFilter(LatLng target, String title) {
    setState(() {
      _showResults = true;
      _targetLocation = target;
      if(!_suggestions.contains(title) && title != "Destino seleccionado" && title != "Ubicación") {
        _searchController.text = title;
      }
      _markers = {
        Marker(markerId: const MarkerId('target'), position: target, infoWindow: InfoWindow(title: title), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
      };
      _statusMessage = "Calculando ruta óptima...";
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
    }

    _calculateRoutesLogic(target);
  }

  // --- 🔹 DIÁLOGO DE GUARDAR FAVORITO 🔹 ---
  void _promptSaveFavorite() {
    final TextEditingController nameCtrl = TextEditingController();
    nameCtrl.text = _searchController.text.isNotEmpty ? _searchController.text : "";

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Guardar ubicación"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Dale un nombre a este lugar:"),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre (Ej: Casa, Trabajo)", border: OutlineInputBorder()),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A148C), foregroundColor: Colors.white),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    // Guardar en Firestore
                    _favoritesService.addFavorite(nameCtrl.text, "Cusco", _targetLocation);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ubicación guardada en favoritos")));
                  }
                },
                child: const Text("Guardar")
            )
          ],
        )
    );
  }

  // --- ALGORITMO GEOMÉTRICO (TU VERSIÓN QUE FUNCIONA BIEN) ---
  void _calculateRoutesLogic(LatLng target) {
    if (_userPosition == null) {
      _getUserLocation().then((_) {
        if(_userPosition != null) _calculateRoutesLogic(target);
      });
      return;
    }
    if (allRoutes.isEmpty) return;

    LatLng userLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    List<Map<String, dynamic>> results = [];
    const double maxWalkDist = 600;

    // 1. DIRECTAS
    for (var route in allRoutes) {
      List<LatLng> points = route['points_raw'];
      int startIndex = _findClosestPointIndex(points, userLatLng);
      int endIndex = _findClosestPointIndex(points, target);

      if (startIndex == -1 || endIndex == -1) continue;

      double distToStart = Geolocator.distanceBetween(
          userLatLng.latitude, userLatLng.longitude,
          points[startIndex].latitude, points[startIndex].longitude
      );
      double distFromEnd = Geolocator.distanceBetween(
          points[endIndex].latitude, points[endIndex].longitude,
          target.latitude, target.longitude
      );

      if (distToStart < maxWalkDist && distFromEnd < maxWalkDist && startIndex < endIndex) {
        List<LatLng> busSegmentPoints = points.sublist(startIndex, endIndex + 1);
        List<Map<String, dynamic>> segments = [
          {'type': 'walk', 'points': [userLatLng, points[startIndex]]},
          {'type': 'bus', 'points': busSegmentPoints, 'name': route['name'], 'color': Colors.purple},
          {'type': 'walk', 'points': [points[endIndex], target]},
        ];
        double totalDistance = _calculateTotalDistance(segments);
        results.add({
          'type': 'direct',
          'number': route['number'],
          'name': route['name'],
          'schedule': route['schedule'],
          'total_distance': totalDistance,
          'segments': segments,
        });
      }
    }

    if (results.isNotEmpty) {
      results.sort((a, b) => (a['total_distance'] as double).compareTo(b['total_distance'] as double));
      setState(() => searchResults = results);
      return;
    }

    // 2. TRANSBORDOS
    setState(() => _statusMessage = "Buscando conexiones...");

    var nearUser = allRoutes.where((r) {
      int idx = _findClosestPointIndex(r['points_raw'], userLatLng);
      if (idx == -1) return false;
      return Geolocator.distanceBetween(userLatLng.latitude, userLatLng.longitude, r['points_raw'][idx].latitude, r['points_raw'][idx].longitude) < maxWalkDist;
    }).toList();

    var nearTarget = allRoutes.where((r) {
      int idx = _findClosestPointIndex(r['points_raw'], target);
      if (idx == -1) return false;
      return Geolocator.distanceBetween(target.latitude, target.longitude, r['points_raw'][idx].latitude, r['points_raw'][idx].longitude) < maxWalkDist;
    }).toList();

    const double transferWalkLimit = 200;

    for (var r1 in nearUser) {
      for (var r2 in nearTarget) {
        if (r1['number'] == r2['number']) continue;

        var intersection = _findIntersection(r1['points_raw'], r2['points_raw'], transferWalkLimit);

        if (intersection != null) {
          int startIdx = _findClosestPointIndex(r1['points_raw'], userLatLng);
          int xferIdx1 = _findClosestPointIndex(r1['points_raw'], intersection);
          int xferIdx2 = _findClosestPointIndex(r2['points_raw'], intersection);
          int endIdx = _findClosestPointIndex(r2['points_raw'], target);

          if (startIdx < xferIdx1 && xferIdx2 < endIdx) {
            List<LatLng> bus1Points = r1['points_raw'].sublist(startIdx, xferIdx1 + 1);
            List<LatLng> bus2Points = r2['points_raw'].sublist(xferIdx2, endIdx + 1);
            List<LatLng> walkToBus1 = [userLatLng, r1['points_raw'][startIdx]];
            List<LatLng> walkTransfer = [r1['points_raw'][xferIdx1], r2['points_raw'][xferIdx2]];
            List<LatLng> walkToDest = [r2['points_raw'][endIdx], target];

            List<Map<String, dynamic>> segments = [
              {'type': 'walk', 'points': walkToBus1},
              {'type': 'bus', 'points': bus1Points, 'name': r1['name'], 'color': Colors.purple},
              {'type': 'walk', 'points': walkTransfer},
              {'type': 'bus', 'points': bus2Points, 'name': r2['name'], 'color': Colors.blue},
              {'type': 'walk', 'points': walkToDest},
            ];

            double totalDistance = _calculateTotalDistance(segments);

            results.add({
              'type': 'transfer',
              'number': "${r1['number']} + ${r2['number']}",
              'name': "${r1['name']} + ${r2['name']}",
              'leg1_name': r1['name'],
              'leg2_name': r2['name'],
              'schedule': r1['schedule'],
              'total_distance': totalDistance,
              'segments': segments
            });
          }
        }
      }
      if (results.length >= 8) break;
    }

    results.sort((a, b) => (a['total_distance'] as double).compareTo(b['total_distance'] as double));

    setState(() {
      searchResults = results;
      if (searchResults.isEmpty) _statusMessage = "No se encontraron rutas viables.";
    });
  }

  // --- HELPERS ---
  double _calculateTotalDistance(List<Map<String, dynamic>> segments) {
    double totalDist = 0;
    for (var segment in segments) {
      List<LatLng> points = List<LatLng>.from(segment['points']);
      for (int i = 0; i < points.length - 1; i++) {
        totalDist += Geolocator.distanceBetween(
            points[i].latitude, points[i].longitude,
            points[i+1].latitude, points[i+1].longitude
        );
      }
    }
    return totalDist;
  }

  int _findClosestPointIndex(List<LatLng> points, LatLng target) {
    double minD = double.infinity;
    int index = -1;
    for (int i = 0; i < points.length; i++) {
      double d = Geolocator.distanceBetween(target.latitude, target.longitude, points[i].latitude, points[i].longitude);
      if (d < minD) { minD = d; index = i; }
    }
    return index;
  }

  LatLng? _findIntersection(List<LatLng> pts1, List<LatLng> pts2, double threshold) {
    for (int i = 0; i < pts1.length; i += 5) {
      for (int j = 0; j < pts2.length; j += 5) {
        if (Geolocator.distanceBetween(pts1[i].latitude, pts1[i].longitude, pts2[j].latitude, pts2[j].longitude) < threshold) return pts1[i];
      }
    }
    return null;
  }

  void _openResult(Map<String, dynamic> result) {
    UserStatsService().logRouteVisit(result['number'], result['name']);
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => TripResultPage(
          routeName: result['name'],
          tripSegments: result['segments'],
          targetLocation: _targetLocation,
          targetName: _searchController.text.isNotEmpty ? _searchController.text : "Destino",
        )
    ));
  }

  void _goToMyLocation() {
    if (_userPosition != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(_userPosition!.latitude, _userPosition!.longitude)));
    } else {
      _getUserLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) return Scaffold(backgroundColor: Color(0xFF4A148C), body: Center(child: Text("Sin internet", style: TextStyle(color:Colors.white))));
    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _targetLocation, zoom: 14.5),
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              if (widget.initialTarget != null) {
                _mapController!.moveCamera(CameraUpdate.newLatLngZoom(widget.initialTarget!, 15));
              }
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: _onMapTap,
            padding: EdgeInsets.only(bottom: _showResults ? 240 : 20),
          ),

          Positioned(
            top: 40, left: 15, right: 15,
            child: Column(children: [
              Card(child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchTextChanged,
                  onSubmitted: _searchLocationFromText,
                  decoration: InputDecoration(
                      hintText: "Buscar destino",
                      prefixIcon: Icon(Icons.place),
                      // 🔹 BOTÓN PARA GUARDAR FAVORITO
                      suffixIcon: _showResults
                          ? IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.red),
                        tooltip: "Guardar ubicación",
                        onPressed: _promptSaveFavorite,
                      )
                          : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _searchLocationFromText(_searchController.text)
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15)
                  )
              )),
              if (_showSuggestionsList) Container(
                  height: 200, color: Colors.white,
                  child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (_,i) => ListTile(title: Text(_suggestions[i]), onTap: () { _searchController.text=_suggestions[i]; _searchLocationFromText(_suggestions[i]); })
                  )
              )
            ]),
          ),

          Positioned(bottom: _showResults?240:30, right: 20, child: FloatingActionButton(onPressed: _goToMyLocation, child: Icon(Icons.my_location), backgroundColor: Color(0xFF4A148C), foregroundColor: Colors.white)),

          if (_showResults)
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.1,
              maxChildSize: 0.6,
              builder: (ctx, scrollCtrl) {
                return Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Text(searchResults.isEmpty ? "Calculando..." : "Opciones de Viaje", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(
                        child: searchResults.isEmpty
                            ? Center(child: Text(_statusMessage, style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: searchResults.length,
                          itemBuilder: (ctx, i) {
                            final r = searchResults[i];
                            bool isXfer = r['type'] == 'transfer';
                            double distKm = (r['total_distance'] as double) / 1000;

                            return Card(
                              child: ListTile(
                                leading: Icon(isXfer ? Icons.transfer_within_a_station : Icons.directions_bus, color: Color(0xFF4A148C)),
                                title: Text(r['name'], style: TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isXfer) ...[
                                      Text("1. Toma ${r['leg1_name']}"),
                                      Text("2. Baja y toma ${r['leg2_name']}"),
                                    ] else
                                      Text("Ruta directa"),

                                    Text("Distancia total: ${distKm.toStringAsFixed(1)} km", style: TextStyle(fontSize: 12, color: Colors.green)),
                                  ],
                                ),
                                onTap: () => _openResult(r),
                              ),
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