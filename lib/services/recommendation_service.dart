import 'dart:math';
import 'package:app_turista/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final String searchQuery = query.toLowerCase().trim();
      final List<Map<String, dynamic>> resultados = [];

      // Buscar en eventos
      final eventosSnapshot = await _firestore.collection('eventos').get();
      for (var doc in eventosSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final nombre = (data['nombre'] ?? '').toString().toLowerCase();

        if (nombre.contains(searchQuery)) {
          resultados.add({
            'type': 'evento',
            'item': data, // <-- Esto es un Map, no un objeto con propiedades
            'id': doc.id,
            'force': 1.0, // Valor por defecto
            'distance': 0.0, // Valor por defecto
            'isAttractive': false, // Valor por defecto
            'itemCharge': 1.0, // Valor por defecto
          });
        }
      }

      // Buscar en lugares (similar a eventos)
      final lugaresSnapshot = await _firestore.collection('lugares').get();
      for (var doc in lugaresSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final nombre = (data['nombre'] ?? '').toString().toLowerCase();

        if (nombre.contains(searchQuery)) {
          resultados.add({
            'type': 'lugar',
            'item': data,
            'id': doc.id,
            'force': 1.0,
            'distance': 0.0,
            'isAttractive': false,
            'itemCharge': 1.0,
          });
        }
      }

      return resultados;
    } catch (e) {
      print('Error buscando items: $e');
      return [];
    }
  }

  // Constante k para la fórmula electromagnética
  static const double k = 1.0;

  // Exponente α ajustable para la distancia
  static const double alpha = 2.0;

  // Calcular fuerza electromagnética adaptada
  double calculateElectromagneticForce({
    required double Qi, // Calificación del usuario al lugar
    required double Qu, // Peso de preferencia del usuario
    required double distance,
  }) {
    if (distance == 0) distance = 0.001; // Evitar división por cero
    return k * (Qi * Qu) / pow(distance, alpha);
  }

  // Calcular Q_i - calificación del usuario para un lugar específico
  Future<double> calculateItemCharge(
    String itemId,
    String userId,
    String itemType,
  ) async {
    try {
      QuerySnapshot calificaciones =
          await _firestore
              .collection(
                itemType == 'evento'
                    ? 'calificaciones'
                    : 'calificaciones_lugares',
              )
              .where('lugarID', isEqualTo: itemId)
              .where('userID', isEqualTo: userId)
              .get();

      if (calificaciones.docs.isNotEmpty) {
        return (calificaciones.docs.first['estrellas'] ?? 1).toDouble();
      }
      return 1.0; // Valor por defecto si no hay calificación
    } catch (e) {
      print('Error calculando Q_i: $e');
      return 1.0;
    }
  }

  // ¡NUEVA FUNCIÓN! - Calcular Q_u basado en preferencias del usuario
  Future<double> calculateUserCharge(String userId, String categoria) async {
    try {
      // Obtener todas las calificaciones del usuario >= 3 estrellas
      QuerySnapshot calificacionesLugares =
          await _firestore
              .collection('calificaciones_lugares')
              .where('userID', isEqualTo: userId)
              .where('estrellas', isGreaterThanOrEqualTo: 3)
              .get();

      QuerySnapshot calificacionesEventos =
          await _firestore
              .collection('calificaciones')
              .where('userID', isEqualTo: userId)
              .where('estrellas', isGreaterThanOrEqualTo: 3)
              .get();

      // Combinar todas las calificaciones altas
      List<double> calificacionesAltas = [];
      Map<String, int> categoriaCount = {};

      // Procesar calificaciones de lugares
      for (var doc in calificacionesLugares.docs) {
        double estrellas = (doc['estrellas'] ?? 3).toDouble();
        calificacionesAltas.add(estrellas);

        // Obtener categoría del lugar para contar preferencias
        try {
          DocumentSnapshot lugar =
              await _firestore.collection('lugares').doc(doc['lugarID']).get();

          if (lugar.exists) {
            String categoriaLugar = lugar['categoria'] ?? 'otros';
            categoriaCount[categoriaLugar] =
                (categoriaCount[categoriaLugar] ?? 0) + 1;
          }
        } catch (e) {
          print('Error obteniendo categoría del lugar: $e');
        }
      }

      // Procesar calificaciones de eventos
      for (var doc in calificacionesEventos.docs) {
        double estrellas = (doc['estrellas'] ?? 3).toDouble();
        calificacionesAltas.add(estrellas);

        // Obtener categoría del evento
        try {
          DocumentSnapshot evento =
              await _firestore
                  .collection('eventos')
                  .doc(
                    doc['lugarID'],
                  ) // Nota: en tu código usas 'lugarID' también para eventos
                  .get();

          if (evento.exists) {
            String categoriaEvento = evento['categoria'] ?? 'otros';
            categoriaCount[categoriaEvento] =
                (categoriaCount[categoriaEvento] ?? 0) + 1;
          }
        } catch (e) {
          print('Error obteniendo categoría del evento: $e');
        }
      }

      // Si no hay calificaciones altas, retornar valor neutro
      if (calificacionesAltas.isEmpty) {
        return 1.0;
      }

      // Calcular promedio de calificaciones altas (esto será la base de Q_u)
      double promedioGeneral =
          calificacionesAltas.reduce((a, b) => a + b) /
          calificacionesAltas.length;

      // Bonus por preferencia de categoría
      double bonusCategoria = 1.0;
      if (categoriaCount.containsKey(categoria)) {
        int countCategoria = categoriaCount[categoria]!;
        int totalCalificaciones = calificacionesAltas.length;

        // Si más del 30% de sus calificaciones altas son de esta categoría, dar bonus
        if (countCategoria / totalCalificaciones > 0.3) {
          bonusCategoria =
              1.0 +
              (countCategoria /
                  totalCalificaciones *
                  0.5); // Bonus máximo de 50%
        }
      }

      // Q_u = promedio de calificaciones altas * bonus de categoría
      double Qu =
          (promedioGeneral / 5.0) *
          bonusCategoria; // Normalizar a 0-1 y aplicar bonus

      return Qu;
    } catch (e) {
      print('Error calculando Q_u: $e');
      return 1.0;
    }
  }

  // Función para determinar si un lugar es "atractivo" para el usuario
  Future<bool> isAttractiveTo(
    String itemId,
    String userId,
    String itemType,
  ) async {
    try {
      // Obtener calificación específica del usuario para este lugar
      double itemCharge = await calculateItemCharge(itemId, userId, itemType);

      // Si el usuario ya calificó este lugar con 3+ estrellas, es atractivo
      if (itemCharge >= 3.0) {
        return true;
      }

      // Si no ha calificado, verificar si es de una categoría que le gusta
      DocumentSnapshot itemDoc =
          await _firestore
              .collection(itemType == 'evento' ? 'eventos' : 'lugares')
              .doc(itemId)
              .get();

      if (itemDoc.exists) {
        String categoria = itemDoc['categoria'] ?? 'otros';
        double userCharge = await calculateUserCharge(userId, categoria);

        // Si Q_u > 1.2, significa que tiene preferencia por esta categoría
        return userCharge > 1.2;
      }

      return false;
    } catch (e) {
      print('Error verificando atractivo: $e');
      return false;
    }
  }

  // Obtener recomendaciones usando el algoritmo electromagnético mejorado
  Future<List<dynamic>> getRecommendations({
    required String userId,
    required Position userPosition,
    String? categoria,
    int limit = 10,
  }) async {
    List<Map<String, dynamic>> recommendations = [];

    try {
      // Obtener eventos
      Query eventosQuery = _firestore.collection('eventos');
      if (categoria != null) {
        eventosQuery = eventosQuery.where('categoria', isEqualTo: categoria);
      }
      QuerySnapshot eventos = await eventosQuery.get();

      // Obtener lugares
      Query lugaresQuery = _firestore.collection('lugares');
      if (categoria != null) {
        lugaresQuery = lugaresQuery.where('categoria', isEqualTo: categoria);
      }
      QuerySnapshot lugares = await lugaresQuery.get();

      // Procesar eventos
      for (var doc in eventos.docs) {
        Evento evento = Evento.fromFirestore(doc);

        // Calcular distancia
        double distance =
            Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              evento.geolocalizacion.latitude,
              evento.geolocalizacion.longitude,
            ) /
            1000; // Convertir a kilómetros

        // Calcular Q_i (calificación del usuario para este evento)
        double itemCharge = await calculateItemCharge(
          evento.id,
          userId,
          'evento',
        );

        // Calcular Q_u (peso de preferencia del usuario para esta categoría)
        double userCharge = await calculateUserCharge(userId, evento.categoria);

        // Verificar si es atractivo para el usuario
        bool isAttractive = await isAttractiveTo(evento.id, userId, 'evento');

        // Calcular fuerza electromagnética
        double force = calculateElectromagneticForce(
          Qi: itemCharge,
          Qu: userCharge,
          distance: distance,
        );

        recommendations.add({
          'item': evento.toMap(),
          'type': 'evento',
          'force': force,
          'distance': distance,
          'itemCharge': itemCharge,
          'userCharge': userCharge,
          'isAttractive': isAttractive,
        });
      }

      // Procesar lugares
      for (var doc in lugares.docs) {
        Lugar lugar = Lugar.fromFirestore(doc);

        // Calcular distancia
        double distance =
            Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              lugar.geolocalizacion.latitude,
              lugar.geolocalizacion.longitude,
            ) /
            1000; // Convertir a kilómetros

        // Calcular Q_i (calificación del usuario para este lugar)
        double itemCharge = await calculateItemCharge(
          lugar.id,
          userId,
          'lugar',
        );

        // Calcular Q_u (peso de preferencia del usuario para esta categoría)
        double userCharge = await calculateUserCharge(userId, lugar.categoria);

        // Verificar si es atractivo para el usuario
        bool isAttractive = await isAttractiveTo(lugar.id, userId, 'lugar');

        // Calcular fuerza electromagnética
        double force = calculateElectromagneticForce(
          Qi: itemCharge,
          Qu: userCharge,
          distance: distance,
        );

        recommendations.add({
          'item': lugar.toMap(),
          'type': 'lugar',
          'force': force,
          'distance': distance,
          'itemCharge': itemCharge,
          'userCharge': userCharge,
          'isAttractive': isAttractive,
        });
      }

      // Ordenar por fuerza electromagnética (mayor fuerza = mejor recomendación)
      recommendations.sort((a, b) => b['force'].compareTo(a['force']));

      // Limitar resultados
      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error obteniendo recomendaciones: $e');
      return [];
    }
  }
}
