import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './login_screen.dart';
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

  final List<Tab> _tabs = const [
    Tab(text: 'Eventos'),
    Tab(text: 'Lugares'),
    Tab(text: 'Favoritos'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              recommendations.where((r) => r['type'] == 'evento').toList();
          _lugaresRecomendados =
              recommendations.where((r) => r['type'] == 'lugar').toList();
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTopSearch() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar eventos o lugares...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onSubmitted: (query) {
          _searchItems(query);
        },
      ),
    );
  }

  void _searchItems(String query) {
    print('Buscando: $query');
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final double force = recommendation['force'];
    final bool isAttractive = recommendation['isAttractive'] ?? false;
    final double itemCharge = recommendation['itemCharge'] ?? 1.0;
    final double userCharge = recommendation['userCharge'] ?? 1.0;

    // Calcular efectos visuales basados en si es atractivo
    final double opacity =
        isAttractive
            ? _calculateAttractiveOpacity(force)
            : _calculateNormalOpacity(force);

    final double scale =
        isAttractive
            ? _calculateAttractiveScale(force)
            : _calculateNormalScale(force);

    // Efecto de "palpitación" para lugares atractivos
    final Color cardColor = isAttractive ? Colors.white : Colors.grey[50]!;

    final Color borderColor =
        isAttractive ? Colors.blue.withOpacity(0.3) : Colors.transparent;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Card(
            color: cardColor,
            elevation: isAttractive ? 4.0 : 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 2),
            ),
            child: Container(
              decoration:
                  isAttractive
                      ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.05),
                            Colors.white,
                            Colors.blue.withOpacity(0.05),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      )
                      : null,
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          recommendation['type'] == 'evento'
                              ? (isAttractive
                                  ? Colors.blue
                                  : Colors.blue.withOpacity(0.6))
                              : (isAttractive
                                  ? Colors.green
                                  : Colors.green.withOpacity(0.6)),
                      child: Icon(
                        recommendation['type'] == 'evento'
                            ? Icons.event
                            : Icons.location_on,
                        color: Colors.white,
                        size: isAttractive ? 24 : 20,
                      ),
                    ),
                    // Efecto de "palpitación" para lugares atractivos
                    if (isAttractive)
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: Duration(seconds: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  recommendation['item'].nombre,
                  style: TextStyle(
                    fontWeight:
                        isAttractive ? FontWeight.bold : FontWeight.normal,
                    color: isAttractive ? Colors.black87 : Colors.black54,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuerza: ${force.toStringAsFixed(2)}',
                      style: TextStyle(
                        color:
                            isAttractive ? Colors.blue[700] : Colors.grey[600],
                        fontWeight:
                            isAttractive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      'Distancia: ${recommendation['distance'].toStringAsFixed(1)} km',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (itemCharge > 1.0) // Mostrar calificación si existe
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(
                            ' ${itemCharge.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (isAttractive)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
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
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: isAttractive ? Colors.blue : Colors.grey,
                  size: 16,
                ),
                onTap:
                    () => _showItemDetails(
                      recommendation['item'],
                      recommendation['type'],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Opacidad para lugares atractivos (más visible)
  double _calculateAttractiveOpacity(double force) {
    return 0.9 + (force / 20).clamp(0.0, 0.1); // Opacidad entre 0.9 y 1.0
  }

  // Opacidad para lugares normales (menos visible)
  double _calculateNormalOpacity(double force) {
    return 0.4 + (force / 25).clamp(0.0, 0.4); // Opacidad entre 0.4 y 0.8
  }

  // Escala para lugares atractivos (más grandes)
  double _calculateAttractiveScale(double force) {
    return 1.0 + (force / 15).clamp(0.0, 0.15); // Escala entre 1.0x y 1.15x
  }

  // Escala para lugares normales (más pequeños)
  double _calculateNormalScale(double force) {
    return 0.85 + (force / 20).clamp(0.0, 0.10); // Escala entre 0.85x y 0.95x
  }

  void _toggleFavorite(String itemId, String type) {
    print('Toggle favorito: $itemId, tipo: $type');
  }

  void _showItemDetails(dynamic item, String type) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(item.nombre),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.descripcion),
                const SizedBox(height: 8),
                if (type == 'evento')
                  Text('Fecha: ${item.fecha.toString().split(' ')[0]}'),
                if (type == 'lugar') Text('Horario: ${item.horario}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _bottomIndex = 1;
                  });
                },
                child: const Text('Ver en mapa'),
              ),
            ],
          ),
    );
  }

  Widget _buildTabContent() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab de Eventos
                      _eventosRecomendados.isEmpty
                          ? const Center(
                            child: Text('No hay eventos recomendados'),
                          )
                          : ListView.builder(
                            itemCount: _eventosRecomendados.length,
                            itemBuilder:
                                (context, index) => _buildRecommendationCard(
                                  _eventosRecomendados[index],
                                ),
                          ),
                      // Tab de Lugares
                      _lugaresRecomendados.isEmpty
                          ? const Center(
                            child: Text('No hay lugares recomendados'),
                          )
                          : ListView.builder(
                            itemCount: _lugaresRecomendados.length,
                            itemBuilder:
                                (context, index) => _buildRecommendationCard(
                                  _lugaresRecomendados[index],
                                ),
                          ),
                      // Tab de Favoritos
                      const Center(child: Text('Favoritos - Por implementar')),
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
        return MapScreen(currentPosition: _currentPosition);
      case 2:
        return isLoggedIn ? _buildPerfilScreen() : const LoginScreen();
      default:
        return const Center(child: Text('Inicio'));
    }
  }

  Widget _buildPerfilScreen() {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80),
            const SizedBox(height: 20),
            Text(
              'Correo: ${user?.email ?? 'Desconocido'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {
                  _bottomIndex = 0; // volver a Inicio tras logout
                });
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _getCurrentPage()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
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
        ],
      ),
    );
  }
}
