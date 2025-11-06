import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'database_helper.dart';
import 'route_model.dart';

class JsonLoader {
  final DatabaseHelper dbh = DatabaseHelper();

  Future<void> importAllFromJson(List<String> assetPaths) async {
    for (final path in assetPaths) {
      final content = await rootBundle.loadString(path);
      final data = jsonDecode(content);

      final route = BusRoute(
        name: data['name'],
        number: data['number'],
        schedule: data['schedule'],
        description: data['description'],
      );

      final routeId = await dbh.insertRoute(route.toMap());

      // Insert points
      final points = (data['points'] as List)
          .map((p) => RoutePoint(
        routeId: routeId,
        lat: (p['lat'] as num).toDouble(),
        lng: (p['lng'] as num).toDouble(),
        seq: (data['points'] as List).indexOf(p),
      ))
          .toList();

      for (var point in points) {
        await dbh.insertPoint(point.toMap());
      }

      // Insert stops
      final stops = (data['stops'] as List?) ?? [];
      for (int i = 0; i < stops.length; i++) {
        final s = stops[i];
        await dbh.insertStop({
          'route_id': routeId,
          'name': s['name'],
          'lat': s['lat'],
          'lng': s['lng'],
          'seq': i,
        });
      }
    }
  }
}
