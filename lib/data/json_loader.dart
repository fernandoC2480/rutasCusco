import 'dart:convert';
import 'package:flutter/material.dart'; // Para debugPrint
import 'package:flutter/services.dart' show rootBundle;
import 'database_helper.dart';
import 'route_model.dart';

class JsonLoader {
  final DatabaseHelper dbh = DatabaseHelper();

  Future<void> importAllFromJson(List<String> assetPaths) async {
    int successCount = 0;

    for (final path in assetPaths) {
      try {
        final content = await rootBundle.loadString(path);
        final data = jsonDecode(content);
        final route = BusRoute(
          name: data['name'] ?? 'Sin Nombre',
          number: data['number'] ?? 'S/N',
          schedule: data['schedule'] ?? '',
          description: data['description'] ?? '',
        );

        final routeId = await dbh.insertRoute(route.toMap());
        final List<dynamic> rawPoints = data['points'] ?? [];
        for (int i = 0; i < rawPoints.length; i++) {
          final p = rawPoints[i];
          await dbh.insertPoint({
            'route_id': routeId,
            'lat': (p['lat'] as num).toDouble(),
            'lng': (p['lng'] as num).toDouble(),
            'seq': i,
          });
        }

        // Insertar Paradas
        final stops = (data['stops'] as List?) ?? [];
        for (int i = 0; i < stops.length; i++) {
          final s = stops[i];
          await dbh.insertStop({
            'route_id': routeId,
            'name': s['name'],
            'lat': (s['lat'] as num).toDouble(),
            'lng': (s['lng'] as num).toDouble(),
            'seq': i,
          });
        }

        successCount++;
        debugPrint("Ruta cargada correctamente: $path");

      } catch (e) {
        debugPrint("Error al importar la ruta $path: $e");
      }
    }

    debugPrint("Total de rutas importadas: $successCount / ${assetPaths.length}");
  }
}