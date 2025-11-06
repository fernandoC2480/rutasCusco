import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/route_model.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({Key? key}) : super(key: key);

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final DatabaseHelper dbh = DatabaseHelper();
  List<BusRoute> routes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final rows = await dbh.getAllRoutes();
    setState(() {
      routes = rows.map((r) => BusRoute.fromMap(r)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas de Bus - Cusco')),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (_, i) {
          final r = routes[i];
          return ListTile(
            title: Text(r.name),
            subtitle: Text('Ruta: ${r.number}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Navegar a map_page pasando routeId
              Navigator.pushNamed(context, '/map', arguments: {'routeId': r.id});
            },
          );
        },
      ),
    );
  }
}
