import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'map_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutesFromJson();
  }

  /// 🔹 Carga todas las rutas desde los archivos JSON
  Future<void> _loadRoutesFromJson() async {
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

        routes.add({
          'name': data['name'],
          'number': data['number'],
          'schedule': data['schedule'],
          'polyline': json.encode(data['polyline']),
        });
      }

      setState(() {
        allRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando rutas: $e');
      setState(() => _isLoading = false);
    }
  }

  void _searchRoute() {
    final query = _searchController.text.toLowerCase();

    final matches = allRoutes.where((route) =>
    route['name'].toLowerCase().contains(query) ||
        route['number'].toLowerCase().contains(query)).toList();

    if (matches.isNotEmpty) {
      final route = matches.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            routeName: route['name'],
            routeNumber: route['number'],
            schedule: route['schedule'],
            polyline: route['polyline'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró ninguna ruta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF4A148C),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF4A148C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_bus, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Buscar ruta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchRoute(),
                decoration: InputDecoration(
                  hintText: 'Ingrese número o nombre de ruta',
                  hintStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4A148C)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _searchRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4A148C),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.search),
                label: const Text(
                  'Buscar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
