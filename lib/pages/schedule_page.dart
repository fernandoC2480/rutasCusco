import 'package:flutter/material.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Horarios de Rutas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildScheduleItem("Ruta A", "Lunes a Viernes: 5:00 AM - 11:00 PM"),
                _buildScheduleItem("Ruta A", "Sábados: 6:00 AM - 10:00 PM"),
                _buildScheduleItem("Ruta A", "Domingos: 7:00 AM - 9:00 PM"),
                _buildScheduleItem("Ruta B", "Lunes a Viernes: 5:30 AM - 10:30 PM"),
                _buildScheduleItem("Ruta B", "Sábados: 6:30 AM - 9:30 PM"),
                _buildScheduleItem("Ruta B", "Domingos: 7:30 AM - 8:30 PM"),
                _buildScheduleItem("Ruta C", "Lunes a Domingo: 6:00 AM - 8:00 PM"),
                _buildScheduleItem("Ruta D", "Lunes a Sábado: 5:00 AM - 11:30 PM"),
                _buildScheduleItem("Ruta D", "Domingos: 6:00 AM - 10:00 PM"),
                _buildScheduleItem("Ruta E", "Lunes a Domingo: 4:30 AM - 10:00 PM"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String route, String schedule) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(schedule, style: const TextStyle(color: Color(0xFF4A148C), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
