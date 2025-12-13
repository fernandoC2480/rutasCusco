import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Registrar una visita a una ruta
  Future<void> logRouteVisit(String routeNumber, String routeName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userStatsRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('route_stats')
        .doc(routeNumber);

    // Usamos set con merge para incrementar el contador o crearlo si no existe
    await userStatsRef.set({
      'routeNumber': routeNumber,
      'routeName': routeName,
      'lastVisited': FieldValue.serverTimestamp(),
      'visitCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // 2. Obtener las rutas más visitadas
  Stream<QuerySnapshot> getMostUsedRoutes() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('route_stats')
        .orderBy('visitCount', descending: true)
        .limit(5)
        .snapshots();
  }
}