import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
    final nombreController = TextEditingController(text: doc?['nombre']);
    final descripcionController = TextEditingController(
      text: doc?['descripcion'],
    );
    final categoriaController = TextEditingController(text: doc?['categoria']);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
                onPressed: () async {
                  final data = {
                    'nombre': nombreController.text,
                    'descripcion': descripcionController.text,
                    'categoria': categoriaController.text,
                  };
                  final collection = tipo == 'evento' ? 'eventos' : 'lugares';
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
                  Navigator.pop(context);
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

  Widget _buildLista(String tipo) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(tipo).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data();
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                title: Text(
                  data['nombre'] ?? '[Sin nombre]',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                subtitle: Text(
                  data['descripcion'] ?? '',
                  style: TextStyle(color: _lightTextColor),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange[700]),
                      onPressed: () => _mostrarFormulario(tipo, doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () =>
                              FirebaseFirestore.instance
                                  .collection(tipo)
                                  .doc(doc.id)
                                  .delete(),
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

  Widget _buildTabContent(String tipo) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () => _mostrarFormulario(tipo),
            icon: const Icon(Icons.add),
            label: Text('Nuevo $tipo'),
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
          tabs: const [Tab(text: 'Eventos'), Tab(text: 'Lugares')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTabContent('eventos'), _buildTabContent('lugares')],
      ),
    );
  }
}
