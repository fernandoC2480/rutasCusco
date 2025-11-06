import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "routes_cusco.db");

    // open/create DB
    return await openDatabase(path,
        version: 1, onCreate: _onCreate, onConfigure: _onConfigure);
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        number TEXT NOT NULL,
        schedule TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE route_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        seq INTEGER NOT NULL,
        FOREIGN KEY(route_id) REFERENCES routes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE stops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER NOT NULL,
        name TEXT,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        seq INTEGER NOT NULL,
        FOREIGN KEY(route_id) REFERENCES routes(id) ON DELETE CASCADE
      )
    ''');
  }

  // CRUD helpers
  Future<int> insertRoute(Map<String, dynamic> map) async {
    final dbClient = await db;
    return await dbClient.insert('routes', map);
  }

  Future<int> insertPoint(Map<String, dynamic> map) async {
    final dbClient = await db;
    return await dbClient.insert('route_points', map);
  }

  Future<int> insertStop(Map<String, dynamic> map) async {
    final dbClient = await db;
    return await dbClient.insert('stops', map);
  }

  Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final dbClient = await db;
    return await dbClient.query('routes');
  }

  Future<List<Map<String, dynamic>>> getPointsForRoute(int routeId) async {
    final dbClient = await db;
    return await dbClient.query(
      'route_points',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'seq ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getStopsForRoute(int routeId) async {
    final dbClient = await db;
    return await dbClient.query(
      'stops',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'seq ASC',
    );
  }

  Future<Map<String, dynamic>?> getRouteById(int id) async {
    final dbClient = await db;
    final res = await dbClient.query('routes', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> deleteAll() async {
    final dbClient = await db;
    await dbClient.delete('route_points');
    await dbClient.delete('stops');
    await dbClient.delete('routes');
  }
}
