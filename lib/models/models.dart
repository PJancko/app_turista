import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fecha;
  final GeoPoint geolocalizacion;
  final String categoria;

  Evento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fecha,
    required this.geolocalizacion,
    required this.categoria,
  });

  // Ya existente
  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evento(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      geolocalizacion: data['geolocalizacion'],
      categoria: data['categoria'] ?? '',
    );
  }

  // 🔥 Nuevo método
  factory Evento.fromMap(Map<String, dynamic> data) {
    return Evento(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      fecha:
          data['fecha'] is Timestamp
              ? (data['fecha'] as Timestamp).toDate()
              : data['fecha'] as DateTime,
      geolocalizacion: data['geolocalizacion'],
      categoria: data['categoria'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha': fecha,
      'geolocalizacion': geolocalizacion,
      'categoria': categoria,
    };
  }
}

class Lugar {
  final String id;
  final String nombre;
  final String descripcion;
  final String horario;
  final GeoPoint geolocalizacion;
  final String categoria;

  Lugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.horario,
    required this.geolocalizacion,
    required this.categoria,
  });

  factory Lugar.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lugar(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      horario: data['horario'] ?? '',
      geolocalizacion: data['geolocalizacion'],
      categoria: data['categoria'] ?? '',
    );
  }

  // 🔥 Nuevo método
  factory Lugar.fromMap(Map<String, dynamic> data) {
    return Lugar(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      horario: data['horario'] ?? '',
      geolocalizacion: data['geolocalizacion'],
      categoria: data['categoria'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'horario': horario,
      'geolocalizacion': geolocalizacion,
      'categoria': categoria,
    };
  }
}

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final List<String> favoritosEventos;
  final List<String> favoritosLugares;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.favoritosEventos,
    required this.favoritosLugares,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      favoritosEventos: List<String>.from(data['favoritosEventos'] ?? []),
      favoritosLugares: List<String>.from(data['favoritosLugares'] ?? []),
    );
  }
}

class Calificacion {
  final String id;
  final String userID;
  final String lugarID; // puede ser lugar o evento ID
  final int estrellas;
  final String fecha;

  Calificacion({
    required this.id,
    required this.userID,
    required this.lugarID,
    required this.estrellas,
    required this.fecha,
  });

  factory Calificacion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Calificacion(
      id: doc.id,
      userID: data['userID'] ?? '',
      lugarID: data['lugarID'] ?? '',
      estrellas: data['estrellas'] ?? 0,
      fecha: data['fecha'] ?? '',
    );
  }
}
