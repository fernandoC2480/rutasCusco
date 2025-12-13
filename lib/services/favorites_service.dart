import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Guardar favorito
  Future<void> addFavorite(String name, String address, LatLng location) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .add({
      'name': name, // Ej: "Casa", "Trabajo"
      'address': address, // Ej: "Av. Cultura 123"
      'lat': location.latitude,
      'lng': location.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Obtener favoritos en tiempo real
  Stream<QuerySnapshot> getFavorites() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Borrar favorito
  Future<void> deleteFavorite(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(docId)
        .delete();
  }
}