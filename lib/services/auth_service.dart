import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream que escucha cambios de estado (Login/Logout)
  // Indispensable para que el SplashScreen funcione
  Stream<User?> get userStream => _auth.authStateChanges();

  // Iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Abrir diálogo de cuentas de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 2. Obtener tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear credencial para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("ERROR EN GOOGLE SIGN-IN: $e");
      return null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;
}