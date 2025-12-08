import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Generado por FlutterFire CLI
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'data/database_helper.dart';
import 'data/json_loader.dart';
import 'pages/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de Firebase con SHA-1 ya configurado
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Lógica de base de datos local
  final dbh = DatabaseHelper();
  final existing = await dbh.getAllRoutes();
  if (existing.isEmpty) {
    final loader = JsonLoader();
    await loader.importAllFromJson([
      'assets/json/ruta_1.json',
      'assets/json/ruta_patron_de_san_jeronimo.json',
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
        // Inyectamos el AuthService corregido
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
        ),
        // La puerta de entrada es siempre el SplashScreen
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}