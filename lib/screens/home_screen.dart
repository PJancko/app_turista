import 'package:flutter/material.dart';
import './login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Eventos',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout>
    with SingleTickerProviderStateMixin {
  int _bottomIndex = 0;
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: 'Eventos'),
    Tab(text: 'Lugares'),
    Tab(text: 'Favoritos'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          child: TabBarView(
            controller: _tabController,
            children: const [
              Center(child: Text('Lista de Eventos')),
              Center(child: Text('Lista de Lugares')),
              Center(child: Text('Favoritos')),
            ],
          ),
        ),
      ],
    );
  }

  // Aquí está la clave: diferentes pantallas dentro del mismo layout
  Widget _getCurrentPage() {
    switch (_bottomIndex) {
      case 0:
        return Column(
          children: [_buildTopSearch(), Expanded(child: _buildTabContent())],
        );
      case 1:
        return const Center(child: Text('Mapa')); // Mapa en el futuro
      case 2:
        return const LoginScreen();
      default:
        return const Center(child: Text('Inicio'));
    }
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
        ],
      ),
    );
  }
}
