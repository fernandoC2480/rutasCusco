import 'dart:convert';
import '../services/user_stats_service.dart';
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

  // Listas para manejar los datos agrupados
  List<Map<String, dynamic>> groupedRoutes = [];
  List<Map<String, dynamic>> filteredRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutesAndGroup();
  }

  Future<void> _loadRoutesAndGroup() async {
    try {
      // 1. Cargar manifiesto
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final jsonPaths = manifestMap.keys
          .where((path) => path.startsWith('assets/json/') && path.endsWith('.json'))
          .toList();

      // 2. Mapa temporal para agrupar por NÚMERO
      Map<String, Map<String, dynamic>> tempGrouped = {};

      for (final path in jsonPaths) {
        final jsonStr = await rootBundle.loadString(path);
        final data = json.decode(jsonStr);

        String number = data['number'] ?? 'Sin Numero';
        String name = data['name'] ?? 'Sin Nombre';
        String schedule = data['schedule'] ?? '';
        List<dynamic> points = data['points'] ?? [];
        String polylineString = json.encode(points);

        if (tempGrouped.containsKey(number)) {
          (tempGrouped[number]!['polylines'] as List<String>).add(polylineString);
        } else {
          tempGrouped[number] = {
            'number': number,
            'name': name,
            'schedule': schedule,
            'polylines': [polylineString],
          };
        }
      }

      List<Map<String, dynamic>> finalRoutesList = tempGrouped.values.toList();

      setState(() {
        groupedRoutes = finalRoutesList;
        filteredRoutes = finalRoutesList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando rutas: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterRoutes(String query) {
    setState(() {
      filteredRoutes = groupedRoutes.where((route) {
        final name = route['name'].toString().toLowerCase();
        final number = route['number'].toString().toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) || number.contains(search);
      }).toList();
    });
  }

  void _openRoute(Map<String, dynamic> route) {
    UserStatsService().logRouteVisit(route['number'], route['name']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          routeName: route['name'],
          routeNumber: route['number'],
          schedule: route['schedule'],
          polyline: '',
          polylinesList: route['polylines'],
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRoutes,
              decoration: InputDecoration(
                hintText: 'Buscar ruta...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A148C)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF4A148C)),
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredRoutes.isEmpty
                ? const Center(child: Text('No se encontraron rutas.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
              itemCount: filteredRoutes.length,
              itemBuilder: (_, i) {
                final r = filteredRoutes[i];
                final int tramos = (r['polylines'] as List).length;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4A148C),
                      child: const Icon(Icons.directions_bus, color: Colors.white),
                    ),
                    title: Text(
                        r['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    subtitle: Text(
                        "${r['number']} • ${tramos > 1 ? 'Ida y Vuelta' : 'Un sentido'}"
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () => _openRoute(r),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}