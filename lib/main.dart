import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Configuraciones generadas por Firebase CLI
import 'firebase_options.dart';

// Servicios y Pantallas de Autenticación
import 'services/auth_service.dart';
import 'screens/splash_screen.dart'; // O 'pages/splash_screen.dart' según dónde lo guardaste

// Base de Datos y Lógica de Rutas
import 'data/database_helper.dart';
import 'data/json_loader.dart';
import 'pages/home_screen.dart';
import 'pages/maproute_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final dbh = DatabaseHelper();
  final existing = await dbh.getAllRoutes();

  if (existing.isEmpty) {
    final loader = JsonLoader();
    await loader.importAllFromJson([
      'assets/json/rtu_01i.json',
      'assets/json/rtu_01v.json',
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Rutas Cusco',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF4A148C),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A148C)),
          useMaterial3: true,
        ),

        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/map': (context) => const MapPage(
            routeName: '',
            routeNumber: '',
            schedule: '',
            polyline: '[]',
          ),
        },
      ),
    );
  }
}