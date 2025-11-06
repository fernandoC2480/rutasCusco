import 'package:flutter/material.dart';
import 'data/database_helper.dart';
import 'data/json_loader.dart';
import 'pages/home_screen.dart';
import 'pages/routes_page.dart';
import 'pages/map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbh = DatabaseHelper();
  final existing = await dbh.getAllRoutes();

  if (existing.isEmpty) {
    final loader = JsonLoader();
    await loader.importAllFromJson([
      'assets/json/ruta_1.json',
      'assets/json/ruta_2.json',
      // ...
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rutas Cusco',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/routes': (context) => const RoutesPage(),
      },
    );
  }
}
