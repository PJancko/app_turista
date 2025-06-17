import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

final _db = FirebaseFirestore.instance;
final _uuid = const Uuid();

Future<void> poblarTodo() async {
  final usuarioId = _uuid.v4();

  // 1. Poblar usuario
  await _db.collection('usuarios').doc(usuarioId).set({
    'nombre': 'Pablo Gonzales',
    'correo': 'pablo@example.com',
    'rol': 'usuario',
    'favoritosEventos': [],
    'favoritosLugares': [],
  });

  // 2. Poblar lugares
  final lugares = [
    {
      'nombre': 'Catedral Metropolitana',
      'descripcion': 'Iglesia histórica en el centro.',
      'horario': '08:00 - 18:00',
      'categoria': 'historia',
      'geolocalizacion': const GeoPoint(-19.0478, -65.2596),
    },
    {
      'nombre': 'Museo de Arte Charcas',
      'descripcion': 'Museo con piezas coloniales.',
      'horario': '09:00 - 17:00',
      'categoria': 'arte',
      'geolocalizacion': const GeoPoint(-19.0451, -65.2583),
    },
  ];

  final lugarIds = <String>[];
  for (var lugar in lugares) {
    final id = _uuid.v4();
    lugarIds.add(id);
    await _db.collection('lugares').doc(id).set(lugar);
  }

  // 3. Poblar eventos
  final eventos = [
    {
      'nombre': 'Festival de Música Andina',
      'descripcion': 'Música folklórica en vivo.',
      'fecha': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
      'categoria': 'musica',
      'geolocalizacion': const GeoPoint(-19.0500, -65.2605),
    },
    {
      'nombre': 'Feria del Libro',
      'descripcion': 'Evento cultural con autores invitados.',
      'fecha': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
      'categoria': 'cultural',
      'geolocalizacion': const GeoPoint(-19.0465, -65.2612),
    },
  ];

  final eventoIds = <String>[];
  for (var evento in eventos) {
    final id = _uuid.v4();
    eventoIds.add(id);
    await _db.collection('eventos').doc(id).set(evento);
  }

  // 4. Calificaciones de lugares
  for (var lugarId in lugarIds) {
    await _db.collection('calificaciones_lugares').add({
      'userID': usuarioId,
      'lugarID': lugarId,
      'estrellas': 4,
      'comentario': 'Muy recomendable',
    });
  }

  // 5. Calificaciones de eventos
  for (var eventoId in eventoIds) {
    await _db.collection('calificaciones').add({
      'userID': usuarioId,
      'lugarID': eventoId, // Usas 'lugarID' también para eventos
      'estrellas': 5,
      'comentario': 'Me encantó el evento',
    });
  }

  print('🔥 Datos de prueba insertados correctamente');
}
