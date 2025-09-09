import 'package:flutter/material.dart';

class RouteModel {
  final String title;
  final String description;
  final Color color;

  RouteModel({
    required this.title,
    required this.description,
    required this.color,
  });
}

final List<RouteModel> routes = [
  RouteModel(
    title: "Ruta A",
    description: "Centro Histórico - Wanchaq - Santiago",
    color: Colors.red,
  ),
  RouteModel(
    title: "Ruta B",
    description: "Plaza de Armas - San Blas - Alto Qosqo",
    color: Colors.green,
  ),
  RouteModel(
    title: "Ruta C",
    description: "Cusco - Poroy - Chinchero",
    color: Colors.orange,
  ),
  RouteModel(
    title: "Ruta D",
    description: "Cusco - San Sebastián - San Jerónimo",
    color: Colors.purple,
  ),
  RouteModel(
    title: "Ruta E",
    description: "Cusco - Urubamba - Ollantaytambo",
    color: Colors.blue,
  ),
];
