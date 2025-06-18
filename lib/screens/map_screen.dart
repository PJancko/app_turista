import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/recommendation_service.dart';
import 'dart:async';
import '../models/models.dart';

class MapScreen extends StatefulWidget {
  final Position? currentPosition;

  const MapScreen({super.key, this.currentPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _isLoading = true;
  final RecommendationService _recommendationService = RecommendationService();
  Map<String, double> _circleRadii = {};
  Timer? _pulseTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadMarkersWithRecommendations();
    _startPulsatingEffect();
    _pulseTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_disposed) return;
      setState(() {
        // actualización de estado
      });
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _pulseTimer?.cancel();
    super.dispose();
  }

  // Crear marcadores con efectos visuales basados en recomendaciones
  Future<void> _loadMarkersWithRecommendations() async {
    try {
      Set<Marker> markers = {};
      Set<Circle> circles = {};

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.currentPosition == null) {
        // Si no hay usuario logueado, cargar marcadores normales
        await _loadBasicMarkers();
        return;
      }

      // Obtener recomendaciones
      List<dynamic> recommendations = await _recommendationService
          .getRecommendations(
            userId: user.uid,
            userPosition: widget.currentPosition!,
            limit: 50, // Cargar más para el mapa
          );

      // Procesar cada recomendación
      for (var recommendation in recommendations) {
        final isAttractive = recommendation['isAttractive'] ?? false;
        final force = recommendation['force'] ?? 1.0;
        String type = recommendation['type'];
        dynamic item;

        if (type == 'evento') {
          item = Evento.fromMap(recommendation['item']);
        } else {
          item = Lugar.fromMap(recommendation['item']);
        }

        if (item?.geolocalizacion == null || item?.nombre == null) continue;

        final LatLng position = LatLng(
          item.geolocalizacion.latitude,
          item.geolocalizacion.longitude,
        );
        // Crear marcador con estilo basado en atractivo
        final BitmapDescriptor markerIcon = await _createCustomMarker(
          type: type,
          isAttractive: isAttractive,
          force: force,
        );

        final String itemDescripcion = item.descripcion ?? '';

        markers.add(
          Marker(
            markerId: MarkerId('${type}_${item.id}'),
            position: position,
            infoWindow: InfoWindow(
              title: item.nombre ?? 'Sin nombre',
              snippet:
                  isAttractive
                      ? '¡Te puede gustar! • $itemDescripcion'
                      : itemDescripcion,
            ),
            icon: markerIcon,
            onTap: () => _showItemDetails(item, type, recommendation),
          ),
        );

        final circleId = 'pulse_${type}_${item.id}';

        circles.add(
          Circle(
            circleId: CircleId(circleId),
            center: position,
            radius: _circleRadii[circleId] ?? 80,
            fillColor: (type == 'evento' ? Colors.blue : Colors.green)
                .withOpacity(0.1),
            strokeColor: (type == 'evento' ? Colors.blue : Colors.green)
                .withOpacity(0.3),
            strokeWidth: 2,
          ),
        );

        _circleRadii[circleId] = 80; // Valor inicial

        print(
          'Item recomendado: ${item.nombre ?? 'Desconocido'} - Atractivo: $isAttractive - Tipo: $type',
        );
      }
      // Agregar marcador de ubicación actual
      if (widget.currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      setState(() {
        _markers = markers;
        _circles = circles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando marcadores con recomendaciones: $e');
      await _loadBasicMarkers(); // Fallback a marcadores básicos
    }
  }

  // Crear marcadores personalizados
  Future<BitmapDescriptor> _createCustomMarker({
    required String type,
    required bool isAttractive,
    required double force,
  }) async {
    // Color exclusivo para recomendados (atractivos)
    if (isAttractive) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
    }

    // Colores normales por tipo
    if (type == 'evento') {
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ); // Azul claro
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueYellow,
      ); // Amarillo
    }
  }

  // Cargar marcadores básicos (sin recomendaciones)
  Future<void> _loadBasicMarkers() async {
    try {
      Set<Marker> markers = {};

      // Cargar eventos
      QuerySnapshot eventos =
          await FirebaseFirestore.instance.collection('eventos').get();

      for (var doc in eventos.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        GeoPoint geoPoint = data['geolocalizacion'];

        markers.add(
          Marker(
            markerId: MarkerId('evento_${doc.id}'),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(
              title: data['nombre'] ?? 'Evento',
              snippet: data['descripcion'] ?? '',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }

      // Cargar lugares
      QuerySnapshot lugares =
          await FirebaseFirestore.instance.collection('lugares').get();

      for (var doc in lugares.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        GeoPoint geoPoint = data['geolocalizacion'];

        markers.add(
          Marker(
            markerId: MarkerId('lugar_${doc.id}'),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(
              title: data['nombre'] ?? 'Lugar',
              snippet: data['descripcion'] ?? '',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      // Agregar marcador de ubicación actual
      if (widget.currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      setState(() {
        _markers = markers;
        _circles = {};
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando marcadores básicos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showItemDetails(
    dynamic item,
    String type,
    Map<String, dynamic> recommendation,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      type == 'evento' ? Icons.event : Icons.location_on,
                      color: type == 'evento' ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item?.nombre ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (recommendation['isAttractive'] ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '¡Te puede gustar!',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item?.descripcion ?? 'Sin descripción',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (type == 'evento' && item?.fecha != null)
                  Text(
                    'Fecha: ${item.fecha.toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 14),
                  ),
                if (type == 'lugar')
                  Text(
                    'Horario: ${item?.horario ?? 'No especificado'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.flash_on, size: 16, color: Colors.blue[700]),
                    Text(
                      ' Fuerza: ${(recommendation['force'] ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    Text(
                      ' ${(recommendation['distance'] ?? 0.0).toStringAsFixed(1)} km',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ubicación por defecto: Sucre, Bolivia
    LatLng defaultLocation = const LatLng(-19.0478, -65.2596);
    LatLng currentLocation =
        widget.currentPosition != null
            ? LatLng(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            )
            : defaultLocation;

    return Scaffold(
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando recomendaciones...'),
                  ],
                ),
              )
              : GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: currentLocation,
                  zoom: 15.0,
                ),
                markers: _markers,
                circles: _circles, // Agregar círculos palpitantes
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _loadMarkersWithRecommendations,
            tooltip: 'Actualizar recomendaciones',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "location",
            onPressed: () {
              if (_mapController != null && widget.currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(currentLocation),
                );
              }
            },
            tooltip: 'Mi ubicación',
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _startPulsatingEffect() {
    const duration = Duration(milliseconds: 300);

    _pulseTimer?.cancel(); // por si ya existe
    _pulseTimer = Timer.periodic(duration, (_) {
      if (_circleRadii.isEmpty) return;

      setState(() {
        _circleRadii.updateAll((key, value) {
          double newRadius = value + 10;
          if (newRadius > 150) newRadius = 50;
          return newRadius;
        });

        // reconstruir círculos con nuevos radios
        _circles =
            _circles.map((circle) {
              final id = circle.circleId.value;
              final newRadius = _circleRadii[id] ?? circle.radius;
              return circle.copyWith(radiusParam: newRadius);
            }).toSet();
      });
    });
  }
}
