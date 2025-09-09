import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Mapa de Cusco',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Aquí se mostrará el mapa con tu ubicación y las rutas cercanas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF4A148C),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Activar GPS'),
              ),
            ],
          ),
        ),
        const Positioned(top: 100, left: 50, child: Icon(Icons.location_on, color: Colors.red, size: 40)),
        const Positioned(top: 200, right: 70, child: Icon(Icons.location_on, color: Colors.green, size: 40)),
        const Positioned(bottom: 150, left: 100, child: Icon(Icons.location_on, color: Colors.orange, size: 40)),
        const Positioned(bottom: 200, right: 40, child: Icon(Icons.location_on, color: Colors.yellow, size: 40)),
        const Positioned(top: 300, left: 180, child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 50)),
      ],
    );
  }
}
