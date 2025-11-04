import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  void _showAcercaDeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A148C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Acerca de Rutas Cusco',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rutas Cusco es una aplicación desarrollada para facilitar el uso del transporte público en la ciudad del Cusco.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '📱 Características principales:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        _buildFeatureItem('• Búsqueda de rutas en tiempo real'),
                        _buildFeatureItem('• Mapas interactivos de transporte'),
                        _buildFeatureItem('• Información de horarios y paraderos'),
                        _buildFeatureItem('• Planificación de viajes'),
                        const SizedBox(height: 12),
                        const Text(
                          '🎯 Misión:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mejorar la experiencia de movilidad de los ciudadanos y turistas en Cusco, proporcionando información actualizada y confiable del transporte público.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 6),
                        const Text(
                          '© 2025 Rutas Cusco\nTodos los derechos reservados',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(color: Color(0xFF4A148C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSoporteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A148C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.contact_support, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Soporte y Contacto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Necesitas ayuda? Estamos aquí para ti.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildContactItem(
                          icon: Icons.email,
                          title: 'Email de Soporte',
                          content: 'soporte@rutascusco.com',
                        ),
                        const SizedBox(height: 10),
                        _buildContactItem(
                          icon: Icons.phone,
                          title: 'Teléfono',
                          content: '+51 984 123 456',
                        ),
                        const SizedBox(height: 10),
                        _buildContactItem(
                          icon: Icons.schedule,
                          title: 'Horario de Atención',
                          content: 'Lun-Vie: 9:00 AM - 6:00 PM\nSábados: 9:00 AM - 1:00 PM',
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          '💬 También puedes:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        _buildFeatureItem('• Reportar problemas técnicos'),
                        _buildFeatureItem('• Sugerir nuevas rutas'),
                        _buildFeatureItem('• Enviar comentarios'),
                        _buildFeatureItem('• Solicitar información'),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(color: Color(0xFF4A148C)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Abriendo cliente de email...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                        ),
                        child: const Text('Contactar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A148C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.update, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Información de Versión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Versión 1.0.0',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fecha de lanzamiento: Abril 2025',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          '✨ Novedades de esta versión:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureItem('• Lanzamiento inicial'),
                        _buildFeatureItem('• Búsqueda de rutas'),
                        _buildFeatureItem('• Mapa interactivo'),
                        _buildFeatureItem('• Sistema de favoritos'),
                        _buildFeatureItem('• Información de horarios'),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tu app está actualizada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(color: Color(0xFF4A148C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  static Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4A148C), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información de la App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          InfoCard(
            icon: Icons.info,
            title: 'Acerca de',
            description: 'Aplicación desarrollada para facilitar el uso del transporte público en Cusco.',
            onTap: () => _showAcercaDeDialog(context),
          ),
          InfoCard(
            icon: Icons.contact_support,
            title: 'Soporte',
            description: 'Para reportar problemas o sugerencias, contacta a: soporte@rutascusco.com',
            onTap: () => _showSoporteDialog(context),
          ),
          InfoCard(
            icon: Icons.update,
            title: 'Versión',
            description: 'Versión 1.0.0',
            onTap: () => _showVersionDialog(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(color: Color(0xFF4A148C), shape: BoxShape.circle),
                      child: const Icon(Icons.directions_bus, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('Rutas Cusco', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Encuentra las mejores rutas de transporte público en la ciudad del Cusco',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4A148C)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}