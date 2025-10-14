class AuthService {
  // Credenciales locales predefinidas
  static const String _defaultEmail = "usuario@cusco.com";
  static const String _defaultPassword = "123456";

  // Verificar credenciales
  bool login(String email, String password) {
    return email == _defaultEmail && password == _defaultPassword;
  }

  // Verificar si el usuario está logueado
  bool isLoggedIn() {
    // En una implementación real, aquí verificarías un token o sesión
    return true; // Por simplicidad, siempre devuelve true después del login
  }

  // Cerrar sesión
  void logout() {
    // Limpiar cualquier dato de sesión local
  }
}