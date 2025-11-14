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

        // --- ¡EL CAMBIO CRÍTICO ESTÁ AQUÍ! ---
        // Tu JSON tiene la clave 'points', no 'polyline'.
        // Asegúrate de que 'points' sea una List<dynamic> y la conviertes a JSON String.
        final List<dynamic> points = data['points'] ?? []; // Usa ?? [] para asegurar que siempre sea una lista, aunque vacía.
        final String polylineJsonString = json.encode(points);
        // --- FIN DEL CAMBIO ---

        routes.add({
          'name': data['name'],
          'number': data['number'],
          'schedule': data['schedule'],
          'polyline': polylineJsonString, // Ahora pasa la cadena JSON correcta
        });
      }

      setState(() {
        allRoutes = routes;
        filteredRoutes = routes;
        _isLoading = false;
      });
      debugPrint('Rutas cargadas desde JSON: ${allRoutes.length}');
    } catch (e, stacktrace) {
      debugPrint('Error cargando rutas desde JSON: $e');
      debugPrint('StackTrace: $stacktrace');
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
    // Aquí route['polyline'] ya es una String JSON, no necesitas volver a codificarla.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          routeName: route['name'],
          routeNumber: route['number'],
          schedule: route['schedule'],
          polyline: route['polyline'], // Esto ya es la cadena JSON correcta
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
      appBar: AppBar(
        title: const Text('Buscar Rutas'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
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
                return Card( // Usar Card para un mejor aspecto
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus, color: Color(0xFF4A148C)),
                    title: Text('${r['number']} - ${r['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Horario: ${r['schedule']}'),
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