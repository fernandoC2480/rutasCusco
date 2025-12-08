import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../pages/home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el AuthService inyectado en el MultiProvider
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        // Mientras Firebase responde, mostramos carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // SI HAY USUARIO: Redirige a Home
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          });
          return _buildLoadingScreen();
        }

        // SI NO HAY USUARIO: Muestra el Login
        return const LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF4A148C),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}