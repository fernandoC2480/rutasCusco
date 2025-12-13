import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Para LatLng
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// SERVICIOS
import '../services/auth_service.dart';
import '../services/user_stats_service.dart';
import '../services/favorites_service.dart'; // 🔹 Importante: Asegúrate de tener este archivo

// PANTALLAS
import '/screens/login_screen.dart';
import 'map_page.dart';
import 'routes_page.dart';
import 'info_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeDashboardTab(onSwitchToMap: () => _onItemTapped(1)),
      const MapSearchPage(),
      const RoutesSearchPage(),
      const InfoPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Cusco'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedIndex == 0 || _selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: "Cerrar sesión",
            )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_filled), label: 'Buses'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Info'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4A148C),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PESTAÑA DASHBOARD (INICIO)
// ---------------------------------------------------------------------------

class HomeDashboardTab extends StatelessWidget {
  final VoidCallback onSwitchToMap;
  final FavoritesService _favoritesService = FavoritesService(); // Instancia del servicio

  HomeDashboardTab({super.key, required this.onSwitchToMap});

  // --- LÓGICA DE NAVEGACIÓN A MAPA ---
  void _goToFavorite(BuildContext context, String name, double lat, double lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSearchPage(
          initialTarget: LatLng(lat, lng),
          initialName: name,
        ),
      ),
    );
  }

  // --- LÓGICA DE BORRADO DE FAVORITOS ---
  void _confirmDeleteFavorite(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Borrar favorito"),
        content: Text("¿Deseas eliminar '$name' de tus favoritos?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _favoritesService.deleteFavorite(docId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$name eliminado."))
              );
            },
            child: const Text("Borrar"),
          )
        ],
      ),
    );
  }

  void _showTarifasDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.monetization_on, color: Color(0xFF4A148C)),
                  SizedBox(width: 10),
                  Text(
                    "Tarifas de Viaje",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildTarifaItem("Pasaje Urbano (General)", "S/ 1.00"),
              _buildTarifaItem("Pasaje Urbano (Medio/Univ.)", "S/ 0.50"),
              const Divider(),
              _buildTarifaItem("Pasaje Interurbano (Saylla/Tipón)", "S/ 2.00"),
              _buildTarifaItem("Pasaje Interurbano (Oropesa)", "S/ 2.50"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A148C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Entendido"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarifaItem(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? "Viajero";
    String firstName = displayName.split(" ")[0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hola, $firstName 👋",
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 5),
          const Text(
            "¿A dónde quieres ir hoy en Cusco?",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
              height: 1.1,
            ),
          ),

          const SizedBox(height: 10),

          // --- BUSCADOR FALSO (Lleva al mapa) ---
          GestureDetector(
            onTap: onSwitchToMap,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.place, color: Color(0xFF4A148C)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "¿A dónde vas?",
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A148C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Buscar",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // --- SECCIÓN: MIS FAVORITOS ---
          const Text("Mis Favoritos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),

          SizedBox(
            height: 50,
            child: StreamBuilder<QuerySnapshot>(
              stream: _favoritesService.getFavorites(),
              builder: (context, snapshot) {
                // Cargando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(color: Color(0xFF4A148C));
                }

                final docs = snapshot.data?.docs ?? [];

                // Sin favoritos
                if (docs.isEmpty) {
                  return GestureDetector(
                    onTap: onSwitchToMap, // Llevar al mapa para agregar uno
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 5),
                            Text("Agregar favorito")
                          ]
                      ),
                    ),
                  );
                }

                // Lista horizontal de favoritos con opción de borrar
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String name = data['name'];
                    final double lat = data['lat'];
                    final double lng = data['lng'];
                    final String docId = docs[index].id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InputChip( // InputChip permite el botón de borrar
                        avatar: const Icon(Icons.favorite, size: 16, color: Colors.red),
                        label: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        elevation: 1,
                        // Configuración de borrado
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onDeleted: () {
                          _confirmDeleteFavorite(context, docId, name);
                        },
                        // Acción principal: Ir al mapa
                        onPressed: () => _goToFavorite(context, name, lat, lng),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          // --- TARJETA DE MAPA INTERACTIVO ---
          GestureDetector(
            onTap: onSwitchToMap,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE1BEE7).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 40, color: Color(0xFF4A148C)),
                    SizedBox(height: 5),
                    Text("Toca para ver el mapa interactivo", style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // --- GRID INFERIOR (Rutas usadas y Horarios) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna Izquierda: Rutas más usadas
              Expanded(
                child: _buildInfoCard(
                  title: "Rutas más usadas",
                  content: StreamBuilder<QuerySnapshot>(
                    stream: UserStatsService().getMostUsedRoutes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(color: Color(0xFF4A148C)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                          "Aún no tienes rutas frecuentes.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['routeName'] ?? 'Ruta';
                          final number = data['routeNumber'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                const Icon(Icons.history, size: 14, color: Color(0xFF4A148C)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    "$number - $name",
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 15),

              // Columna Derecha: Horarios y Tarifas
              Expanded(
                child: Column(
                  children: [
                    _buildInfoCard(
                      title: "Horarios",
                      content: const Text(
                        "6:00 AM - 10:00 PM",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () => _showTarifasDialog(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.payments_outlined, size: 18, color: Colors.green),
                                SizedBox(width: 5),
                                Text("Tarifas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text("Urbano e Inter.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text("Ver precios >", style: TextStyle(fontSize: 12, color: Color(0xFF4A148C), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}