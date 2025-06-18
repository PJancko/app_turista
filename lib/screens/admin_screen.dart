import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import './map_select_screen.dart'; // importa la pantalla de selección

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  LatLng? _ubicacion;
  final Color _primaryColor = const Color(0xFFD32F2F);
  final Color _secondaryColor = const Color(0xFFFFFFFF);
  final Color _accentColor = const Color(0xFFFFCDD2);
  final Color _textColor = const Color(0xFF212121);
  final Color _lightTextColor = const Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _mostrarFormulario(String tipo, [DocumentSnapshot? doc]) {
    final isEdit = doc != null;
    final nombreController = TextEditingController(text: doc?['nombre'] ?? '');
    final descripcionController = TextEditingController(
      text: doc?['descripcion'] ?? '',
    );
    final categoriaController = TextEditingController(
      text: doc?['categoria'] ?? '',
    );

    // Controladores específicos para cada tipo
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;
    final horarioController = TextEditingController(
      text:
          (tipo == 'lugar' &&
                  doc != null &&
                  ((doc.data() as Map<String, dynamic>).containsKey('horario')))
              ? doc['horario']
              : '',
    );

    LatLng? ubicacion = _ubicacion;

    // Si es edición y hay ubicación en el doc, inicialízala
    if (isEdit && doc?['geolocalizacion'] != null) {
      final geoPoint = doc!['geolocalizacion'] as GeoPoint;
      ubicacion = LatLng(geoPoint.latitude, geoPoint.longitude);
    }

    // Si es edición de evento y hay fecha, inicialízala
    if (isEdit && tipo == 'evento' && doc?['fecha'] != null) {
      final timestamp = doc!['fecha'] as Timestamp;
      fechaSeleccionada = timestamp.toDate();
    }

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    isEdit ? 'Editar $tipo' : 'Nuevo $tipo',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInputField('Nombre', nombreController),
                        const SizedBox(height: 12),
                        _buildInputField('Descripción', descripcionController),
                        const SizedBox(height: 12),
                        _buildInputField('Categoría', categoriaController),
                        const SizedBox(height: 12),

                        // Campos específicos para EVENTOS
                        if (tipo == 'evento') ...[
                          // Selector de fecha
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha del evento',
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fechaSeleccionada != null
                                            ? '${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}'
                                            : 'Seleccionar fecha',
                                        style: TextStyle(
                                          color:
                                              fechaSeleccionada != null
                                                  ? _textColor
                                                  : _lightTextColor,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final fecha = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              fechaSeleccionada ??
                                              DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                        );
                                        if (fecha != null) {
                                          setState(() {
                                            fechaSeleccionada = fecha;
                                          });
                                        }
                                      },
                                      child: const Text('Cambiar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Campos específicos para LUGARES
                        if (tipo == 'lugar') ...[
                          _buildInputField(
                            'Horario (ej: 09:00 - 17:00)',
                            horarioController,
                          ),
                          const SizedBox(height: 12),
                        ],

                        ElevatedButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text('Seleccionar ubicación en el mapa'),
                          onPressed: () async {
                            try {
                              final LatLng? nuevaUbicacion =
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MapSelectScreen(
                                            ubicacionInicial: ubicacion,
                                          ),
                                    ),
                                  );
                              if (nuevaUbicacion != null && mounted) {
                                setState(() {
                                  ubicacion = nuevaUbicacion;
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Error al seleccionar ubicación',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        if (ubicacion != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Ubicación: ${ubicacion!.latitude.toStringAsFixed(6)}, ${ubicacion!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: _lightTextColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          ubicacion == null
                              ? null
                              : () async {
                                // Validación básica
                                if (nombreController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('El nombre es obligatorio'),
                                    ),
                                  );
                                  return;
                                }

                                // Validación específica para eventos
                                if (tipo == 'evento' &&
                                    fechaSeleccionada == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'La fecha del evento es obligatoria',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  // Datos comunes
                                  Map<String, dynamic> data = {
                                    'nombre': nombreController.text.trim(),
                                    'descripcion':
                                        descripcionController.text.trim(),
                                    'categoria':
                                        categoriaController.text.trim(),
                                    'geolocalizacion': GeoPoint(
                                      ubicacion!.latitude,
                                      ubicacion!.longitude,
                                    ),
                                  };

                                  // Datos específicos según el tipo
                                  if (tipo == 'evento') {
                                    // Para eventos: usar Timestamp para la fecha
                                    data['fecha'] = Timestamp.fromDate(
                                      fechaSeleccionada!,
                                    );
                                  } else if (tipo == 'lugar') {
                                    // Para lugares: usar String para el horario
                                    data['horario'] =
                                        horarioController.text.trim();
                                  }

                                  // Determinar la colección correcta
                                  final collection =
                                      tipo == 'evento' ? 'eventos' : 'lugares';

                                  if (isEdit) {
                                    await FirebaseFirestore.instance
                                        .collection(collection)
                                        .doc(doc!.id)
                                        .update(data);
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection(collection)
                                        .add(data);
                                  }

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${tipo.toUpperCase()} ${isEdit ? 'actualizado' : 'creado'} exitosamente',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _accentColor.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(color: _textColor),
      ),
    );
  }

  void _confirmarEliminacion(String tipo, String docId, String nombre) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Estás seguro de eliminar "$nombre"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final collection =
                        tipo == 'eventos' ? 'eventos' : 'lugares';
                    await FirebaseFirestore.instance
                        .collection(collection)
                        .doc(docId)
                        .delete();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$nombre eliminado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildLista(String tipo) {
    // Determinar la colección correcta
    final collection = tipo == 'eventos' ? 'eventos' : 'lugares';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tipo == 'eventos' ? Icons.event_busy : Icons.place_outlined,
                  size: 64,
                  color: _lightTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay ${tipo} registrados',
                  style: TextStyle(fontSize: 18, color: _lightTextColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryColor,
                  child: Icon(
                    tipo == 'eventos' ? Icons.event : Icons.place,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  data['nombre'] ?? '[Sin nombre]',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['descripcion'] ?? '',
                      style: TextStyle(color: _lightTextColor),
                    ),
                    if (data['categoria'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['categoria'],
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (tipo == 'eventos' && data['fecha'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Fecha: ${_formatearFecha(data['fecha'] as Timestamp)}',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (tipo == 'lugares' && data['horario'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Horario: ${data['horario']}',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange[700]),
                      onPressed:
                          () => _mostrarFormulario(
                            tipo == 'eventos' ? 'evento' : 'lugar',
                            doc,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () => _confirmarEliminacion(
                            tipo,
                            doc.id,
                            data['nombre'] ?? 'Elemento',
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  Widget _buildTabContent(String tipo) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed:
                () =>
                    _mostrarFormulario(tipo == 'eventos' ? 'evento' : 'lugar'),
            icon: const Icon(Icons.add),
            label: Text('Nuevo ${tipo == 'eventos' ? 'Evento' : 'Lugar'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: _secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(child: _buildLista(tipo)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: Text(
          'Panel de Administración',
          style: TextStyle(color: _textColor),
        ),
        backgroundColor: _accentColor,
        iconTheme: IconThemeData(color: _primaryColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: _lightTextColor,
          indicatorColor: _primaryColor,
          tabs: const [
            Tab(text: 'Eventos', icon: Icon(Icons.event)),
            Tab(text: 'Lugares', icon: Icon(Icons.place)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTabContent('eventos'), _buildTabContent('lugares')],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
