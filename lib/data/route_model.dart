class BusRoute {
  int? id;
  String name;
  String number;
  String? schedule;
  String? description;

  BusRoute({
    this.id,
    required this.name,
    required this.number,
    this.schedule,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'schedule': schedule,
      'description': description,
    };
  }

  factory BusRoute.fromMap(Map<String, dynamic> m) => BusRoute(
    id: m['id'] as int?,
    name: m['name'] as String,
    number: m['number'] as String,
    schedule: m['schedule'] as String?,
    description: m['description'] as String?,
  );
}

class RoutePoint {
  int? id;
  int routeId;
  double lat;
  double lng;
  int seq;

  RoutePoint({
    this.id,
    required this.routeId,
    required this.lat,
    required this.lng,
    required this.seq,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'lat': lat,
      'lng': lng,
      'seq': seq,
    };
  }

  factory RoutePoint.fromMap(Map<String, dynamic> m) => RoutePoint(
    id: m['id'] as int?,
    routeId: m['route_id'] as int,
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    seq: m['seq'] as int,
  );
}

class Stop {
  int? id;
  int routeId;
  String name;
  double lat;
  double lng;
  int seq;

  Stop({
    this.id,
    required this.routeId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.seq,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'seq': seq,
    };
  }

  factory Stop.fromMap(Map<String, dynamic> m) => Stop(
    id: m['id'] as int?,
    routeId: m['route_id'] as int,
    name: m['name'] as String,
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    seq: m['seq'] as int,
  );
}
