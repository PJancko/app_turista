import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import './login_screen.dart';
import './admin_screen.dart';
import './map_screen.dart';
import '../services/recommendation_service.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout>
    with SingleTickerProviderStateMixin {
  int _bottomIndex = 0;
  late TabController _tabController;
  final RecommendationService _recommendationService = RecommendationService();

  List<dynamic> _eventosRecomendados = [];
  List<dynamic> _lugaresRecomendados = [];
  List<dynamic> _favoritosData = [];
  bool _isLoading = false;
  Position? _currentPosition;
  String? _userRole;

  final List<Tab> _tabs = const [Tab(text: 'Eventos'), Tab(text: 'Lugares')];

  // Colores principales
  final Color _primaryColor = const Color(0xFFD32F2F); // Rojo intenso
  final Color _secondaryColor = const Color(0xFFFFFFFF); // Blanco
  final Color _accentColor = const Color(0xFFFFCDD2); // Rojo claro
  final Color _textColor = const Color(0xFF212121); // Negro oscuro
  final Color _lightTextColor = const Color(0xFF757575); // Gris

  Widget _buildMapLegend() {
    return Positioned(
      top: 20, // Más arriba
      left: 24,
      right: 20,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                color: Colors.blue,
                icon: Icons.place,
                title: 'Eventos',
                subtitle: 'Actividades y\ncelebraciones',
              ),
              _buildLegendItem(
                color: Colors.yellow[700]!,
                icon: Icons.place,
                title: 'Lugares',
                subtitle: 'Sitios turísticos\ny puntos clave',
              ),
              _buildLegendItem(
                color: const Color.fromARGB(255, 224, 49, 204),
                icon: Icons.place,
                title: 'Recomendados',
                subtitle: 'Según tus\npreferencias',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 12, // Más pequeño
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 9, color: _lightTextColor),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _getCurrentLocation();
    _loadUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        setState(() {
          _userRole = doc['rol'] ?? 'usuario';
        });
      }
    } else {
      setState(() {
        _userRole = null; // o 'usuario', según tu lógica
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
        });
        _loadRecommendations();
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');

      setState(() {
        _currentPosition = Position(
          latitude: -19.0478,
          longitude: -65.2596,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
          floor: 0,
          isMocked: false,
        );
      });
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _currentPosition != null) {
        final recommendations = await _recommendationService.getRecommendations(
          userId: user.uid,
          userPosition: _currentPosition!,
        );
        setState(() {
          _eventosRecomendados =
              recommendations
                  .where((r) => r['type'] == 'evento')
                  .map((r) => _normalizarRecommendation(r))
                  .toList();

          _lugaresRecomendados =
              recommendations
                  .where((r) => r['type'] == 'lugar')
                  .map((r) => _normalizarRecommendation(r))
                  .toList();
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTopSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: _secondaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar eventos o lugares...',
          hintStyle: TextStyle(color: _lightTextColor),
          prefixIcon: Icon(Icons.search, color: _primaryColor),
          filled: true,
          fillColor: _accentColor.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (query) {
          _searchItems(query);
        },
      ),
    );
  }

  Future<void> _searchItems(String query) async {
    if (query.isEmpty) {
      // Si no hay búsqueda, vuelve a cargar las recomendaciones
      await _loadRecommendations();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultados = await _recommendationService.searchItems(query);

      setState(() {
        _eventosRecomendados =
            resultados
                .where((r) => r['type'] == 'evento')
                .map((r) => _normalizarRecommendation(r))
                .toList();

        _lugaresRecomendados =
            resultados
                .where((r) => r['type'] == 'lugar')
                .map((r) => _normalizarRecommendation(r))
                .toList();
      });
    } catch (e) {
      print('Error al buscar items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _normalizarRecommendation(Map<String, dynamic> r) {
    final dynamic item = r['item'];

    Map<String, dynamic> normalizado;

    if (item is Map<String, dynamic>) {
      // Ya es un mapa, usar directamente
      normalizado = item;
    } else {
      // Es un objeto (clase personalizada), intentar acceder con getters
      try {
        normalizado = {
          'id': item.id,
          'nombre': item.nombre,
          'descripcion': item.descripcion,
          'fecha': item.fecha,
          'horario': item.horario,
          // agrega más campos si necesitas
        };
      } catch (e) {
        // Fallback si algo sale mal
        normalizado = {
          'nombre': '[Sin nombre]',
          'descripcion': '[Sin descripción]',
        };
      }
    }
    return {...r, 'item': normalizado};
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final dynamic item = recommendation['item'];
    final nombre =
        (item is Map && item.containsKey('nombre'))
            ? item['nombre']
            : '[Sin nombre]';
    final double force = recommendation['force'];
    final bool isAttractive = recommendation['isAttractive'] ?? false;
    final double itemCharge = recommendation['itemCharge'] ?? 1.0;
    final double userCharge = recommendation['userCharge'] ?? 1.0;

    final double opacity =
        isAttractive
            ? _calculateAttractiveOpacity(force)
            : _calculateNormalOpacity(force);

    final double scale =
        isAttractive
            ? _calculateAttractiveScale(force)
            : _calculateNormalScale(force);

    // Colores basados en el tipo
    final Color typeColor =
        recommendation['type'] == 'evento' ? _primaryColor : Colors.green[700]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Card(
            elevation: isAttractive ? 6.0 : 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isAttractive
                        ? typeColor.withOpacity(0.3)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap:
                  () => _showItemDetails(
                    recommendation['item'],
                    recommendation['type'],
                  ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Icono con efecto especial
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(isAttractive ? 0.9 : 0.7),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow:
                            isAttractive
                                ? [
                                  BoxShadow(
                                    color: typeColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                                : null,
                      ),
                      child: Icon(
                        recommendation['type'] == 'evento'
                            ? Icons.event
                            : Icons.place,
                        color: _secondaryColor,
                        size: isAttractive ? 28 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isAttractive
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                              color: _textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.linear_scale,
                                size: 16,
                                color: typeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Fuerza: ${force.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: typeColor,
                                  fontWeight:
                                      isAttractive
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.directions_walk,
                                size: 16,
                                color: _lightTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${recommendation['distance'].toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _lightTextColor,
                                ),
                              ),
                            ],
                          ),
                          if (itemCharge > 1.0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${itemCharge.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isAttractive)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: typeColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '¡Recomendado para ti!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _lightTextColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateAttractiveOpacity(double force) {
    return 0.95 + (force / 20).clamp(0.0, 0.05);
  }

  double _calculateNormalOpacity(double force) {
    return 0.6 + (force / 25).clamp(0.0, 0.3);
  }

  double _calculateAttractiveScale(double force) {
    return 1.0 + (force / 15).clamp(0.0, 0.1);
  }

  double _calculateNormalScale(double force) {
    return 0.9 + (force / 20).clamp(0.0, 0.08);
  }

  void _toggleFavorite(String itemId, String type) {
    print('Toggle favorito: $itemId, tipo: $type');
  }

  void _showItemDetails(dynamic item, String type) {
    double _rating = 3.0;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: _secondaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StatefulBuilder(
                builder:
                    (context, setState) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nombre'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['descripcion'] ?? 'Sin descripción',
                          style: TextStyle(fontSize: 15, color: _textColor),
                        ),
                        const SizedBox(height: 12),
                        if (type == 'evento')
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fecha: ${item['fecha']?.toString().split(' ')[0] ?? 'Sin fecha'}',
                                style: TextStyle(color: _textColor),
                              ),
                            ],
                          ),
                        if (type == 'lugar')
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Horario: ${item['horario'] ?? 'Sin horario'}',
                                style: TextStyle(color: _textColor),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // ★ Calificación ★
                        Text(
                          'Califica este ${type == 'evento' ? 'evento' : 'lugar'}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RatingBar.builder(
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 30,
                          itemPadding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                          ),
                          unratedColor: Colors.grey[300],
                          itemBuilder:
                              (context, _) =>
                                  Icon(Icons.star, color: Colors.amber[700]),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _rating = rating;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: _lightTextColor,
                              ),
                              child: const Text('Cerrar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  final calificacionData = {
                                    'userID': user.uid,
                                    'lugarID': item['id'] ?? 'sin_id',
                                    'estrellas': _rating.toInt(),
                                    'fecha': Timestamp.now(),
                                  };

                                  final collection =
                                      type == 'evento'
                                          ? 'calificaciones'
                                          : 'calificaciones_lugares';

                                  await FirebaseFirestore.instance
                                      .collection(collection)
                                      .add(calificacionData);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('¡Gracias por calificar!'),
                                      backgroundColor: _primaryColor,
                                    ),
                                  );
                                }

                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Guardar y cerrar'),
                            ),
                          ],
                        ),
                      ],
                    ),
              ),
            ),
          ),
    );
  }

  Widget _buildTabContent() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _secondaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            tabs: _tabs,
            labelColor: _primaryColor,
            unselectedLabelColor: _lightTextColor,
            indicatorColor: _primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab de Eventos
                      _eventosRecomendados.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 50,
                                  color: _lightTextColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay eventos recomendados',
                                  style: TextStyle(color: _lightTextColor),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: _eventosRecomendados.length,
                            itemBuilder:
                                (context, index) => _buildRecommendationCard(
                                  _eventosRecomendados[index],
                                ),
                          ),
                      // Tab de Lugares
                      _lugaresRecomendados.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.place,
                                  size: 50,
                                  color: _lightTextColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay lugares recomendados',
                                  style: TextStyle(color: _lightTextColor),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: _lugaresRecomendados.length,
                            itemBuilder:
                                (context, index) => _buildRecommendationCard(
                                  _lugaresRecomendados[index],
                                ),
                          ),
                      // Eliminado el tercer Tab (Favoritos)
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _getCurrentPage() {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    switch (_bottomIndex) {
      case 0:
        return Column(
          children: [_buildTopSearch(), Expanded(child: _buildTabContent())],
        );
      case 1:
        return Stack(
          children: [
            MapScreen(currentPosition: _currentPosition),
            _buildMapLegend(), // Agrega la leyenda aquí
          ],
        );
      case 2:
        return isLoggedIn
            ? _buildPerfilScreen()
            : LoginScreen(
              onLoginSuccess: () async {
                await _loadUserRole();
                await _loadRecommendations();
                setState(() {});
              },
            );
      case 3:
        return const AdminScreen();
      default:
        return const Center(child: Text('Inicio'));
    }
  }

  Widget _buildPerfilScreen() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withOpacity(0.1),
                border: Border.all(color: _primaryColor, width: 2),
              ),
              child: Icon(Icons.person, size: 60, color: _primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Mi Perfil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileInfoRow(
                      Icons.email,
                      'Correo',
                      user?.email ?? 'Desconocido',
                    ),
                    const Divider(height: 24),
                    _buildProfileInfoRow(Icons.person, 'Nombre', 'Usuario'),
                    const Divider(height: 24),
                    _buildProfileInfoRow(
                      Icons.phone,
                      'Teléfono',
                      'No especificado',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await _loadUserRole();
                  await _loadRecommendations();
                  setState(() {
                    _bottomIndex = 0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Sesión cerrada'),
                      backgroundColor: _primaryColor,
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: _lightTextColor)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      body: SafeArea(child: _getCurrentPage()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
        selectedItemColor: _primaryColor,
        unselectedItemColor: _lightTextColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: Icon(
              FirebaseAuth.instance.currentUser != null
                  ? Icons.person
                  : Icons.login,
            ),
            label:
                FirebaseAuth.instance.currentUser != null ? 'Perfil' : 'Login',
          ),
          if (_userRole == 'admin')
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Administrar',
            ),
        ],
      ),
    );
  }
}
