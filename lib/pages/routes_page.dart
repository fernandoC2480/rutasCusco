import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'maproute_page.dart';

class RoutesSearchPage extends StatefulWidget {
  const RoutesSearchPage({Key? key}) : super(key: key);

  @override
  State<RoutesSearchPage> createState() => _RoutesSearchPageState();
}

class _RoutesSearchPageState extends State<RoutesSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allRoutes = [];
  List<Map<String, dynamic>> filteredRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutesFromJson();
  }

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
        filteredRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando rutas: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterRoutes(String query) {
    setState(() {
      filteredRoutes = allRoutes.where((route) {
        final name = route['name'].toLowerCase();
        final number = route['number'].toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) || number.contains(search);
      }).toList();
    });
  }

  void _openRoute(Map<String, dynamic> route) {
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
      body: Column(
        children: [
          // 🔹 Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRoutes,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o número de ruta...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A148C)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF4A148C)),
                ),
              ),
            ),
          ),

          // 🔹 Lista de resultados o sugerencias
          Expanded(
            child: filteredRoutes.isEmpty
                ? const Center(
              child: Text(
                'No se encontraron rutas.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: filteredRoutes.length,
              itemBuilder: (_, i) {
                final r = filteredRoutes[i];
                return ListTile(
                  leading: const Icon(Icons.directions_bus, color: Color(0xFF4A148C)),
                  title: Text(r['name']),
                  subtitle: Text('Ruta: ${r['number']} - ${r['schedule']}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _openRoute(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
