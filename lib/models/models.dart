import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final DateTime fecha;
  final GeoPoint geolocalizacion;
  final String ubicacion;
  final String estado;
  final String creadoPor;

  Evento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.fecha,
    required this.geolocalizacion,
    required this.ubicacion,
    required this.estado,
    required this.creadoPor,
  });

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Evento(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      categoria: data['categoria'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      geolocalizacion: data['geolocalizacion'] as GeoPoint,
      ubicacion: data['ubicacion'] ?? '',
      estado: data['estado'] ?? 'activo',
      creadoPor: data['creadoPor'] ?? '',
    );
  }
}

class Lugar {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final GeoPoint geolocalizacion;
  final String horario;
  final String creadoPor;

  Lugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.geolocalizacion,
    required this.horario,
    required this.creadoPor,
  });

  factory Lugar.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lugar(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      categoria: data['categoria'] ?? '',
      geolocalizacion: data['geolocalizacion'] as GeoPoint,
      horario: data['horario'] ?? '',
      creadoPor: data['creadoPor'] ?? '',
    );
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
