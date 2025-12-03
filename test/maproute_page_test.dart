import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Asegúrate de importar tu archivo correcto. 
// Si tu archivo se llama map_page.dart, úsalo. Si es otro, cámbialo aquí.
import 'package:proyecto_rutas2/pages/maproute_page.dart'; 

// -------------------------------------------------------------------------
// DEFINICIÓN DEL MOCK
// -------------------------------------------------------------------------
// Usamos 'with MockPlatformInterfaceMixin' para que Flutter sepa que es un plugin válido.
// Al extender de 'Mock', no necesitamos implementar bearingBetween, distanceBetween, etc.
class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

// Clase falsa para satisfacer los argumentos de mocktail
class FakeLocationSettings extends Fake implements LocationSettings {}

void main() {
  late MockGeolocatorPlatform mockGeolocator;

  setUpAll(() {
    // Registramos valores por defecto para evitar errores de argumentos en Mocktail
    registerFallbackValue(FakeLocationSettings());
  });

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    
    // Inyectamos nuestro mock en la plataforma
    GeolocatorPlatform.instance = mockGeolocator;

    // -----------------------------------------------------------
    // STUBS (Respuestas predefinidas)
    // -----------------------------------------------------------
    
    // 1. Servicio habilitado
    when(() => mockGeolocator.isLocationServiceEnabled())
        .thenAnswer((_) async => true);

    // 2. Permisos aceptados (check)
    when(() => mockGeolocator.checkPermission())
        .thenAnswer((_) async => LocationPermission.always);

    // 3. Permisos aceptados (request)
    when(() => mockGeolocator.requestPermission())
        .thenAnswer((_) async => LocationPermission.always);

    // 4. Posición actual (getCurrentPosition)
    // Importante: Usamos any(named: 'locationSettings') para capturar cualquier configuración
    when(() => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        )).thenAnswer((_) async => Position(
          longitude: -71.967463,
          latitude: -13.53195,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0, 
          altitudeAccuracy: 0.0, 
          headingAccuracy: 0.0,
          isMocked: true, // Opcional, pero buena práctica
        ));
        
    // 5. Stream de posición (opcional, por si tu código lo usa en el futuro)
    when(() => mockGeolocator.getPositionStream(
          locationSettings: any(named: 'locationSettings'),
        )).thenAnswer((_) => const Stream.empty());
  });

  // Datos de prueba
  const String testRouteName = "Ruta Centro";
  const String testRouteNumber = "RT-101";
  const String testSchedule = "06:00 - 22:00";
  const String validPolylineJson = '[{"lat": -13.5, "lng": -71.9}, {"lat": -13.6, "lng": -71.8}]';
  const String invalidPolylineJson = 'esto no es json';

  group('MapPage Widget Tests', () {
    
    testWidgets('Renderiza info de ruta y mapa correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MapPage(
          routeName: testRouteName,
          routeNumber: testRouteNumber,
          schedule: testSchedule,
          polyline: validPolylineJson,
        ),
      ));

      // Verificar textos
      expect(find.text('$testRouteNumber - $testRouteName'), findsOneWidget);
      expect(find.text('Horario: $testSchedule'), findsOneWidget);
      
      // Verificar que el mapa está ahí
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('Muestra error (SnackBar) si el JSON es inválido', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MapPage(
          routeName: testRouteName,
          routeNumber: testRouteNumber,
          schedule: testSchedule,
          polyline: invalidPolylineJson,
        ),
      ));

      // Esperar a que se ejecute el initState y el parseo falle
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error al cargar la ruta'), findsOneWidget);
    });

    testWidgets('El botón de ubicación invoca al GPS', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MapPage(
          routeName: testRouteName,
          routeNumber: testRouteNumber,
          schedule: testSchedule,
          polyline: validPolylineJson,
        ),
      ));

      // Buscar botón de ubicación
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Tocar el botón
      await tester.tap(fabFinder);
      await tester.pump(); // Iniciar animación/futuro
      
      // Verificamos con Mocktail que se llamó a la función
      verify(() => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).called(greaterThan(0)); 
    });
  });
}