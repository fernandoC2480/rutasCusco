import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información de la App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const InfoCard(
            icon: Icons.info,
            title: 'Acerca de',
            description: 'Aplicación desarrollada para facilitar el uso del transporte público en Cusco.',
          ),
          const InfoCard(
            icon: Icons.contact_support,
            title: 'Soporte',
            description: 'Para reportar problemas o sugerencias, contacta a: soporte@rutascusco.com',
          ),
          const InfoCard(
            icon: Icons.update,
            title: 'Versión',
            description: 'Versión 1.0.0',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(color: Color(0xFF4A148C), shape: BoxShape.circle),
                    child: const Icon(Icons.directions_bus, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('Rutas Cusco', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'Encuentra las mejores rutas de transporte público en la ciudad del Cusco',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4A148C)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}