import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectScreen extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const MapSelectScreen({super.key, this.ubicacionInicial});

  @override
  State<MapSelectScreen> createState() => _MapSelectScreenState();
}

class _MapSelectScreenState extends State<MapSelectScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLocation;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.ubicacionInicial;
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted && mounted) {
      _controller.complete(controller);
      setState(() {
        _mapReady = true;
      });
    }
  }

  void _onTap(LatLng location) {
    if (mounted) {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        onTap: _onTap,
        initialCameraPosition: CameraPosition(
          target:
              widget.ubicacionInicial ??
              const LatLng(-19.0336, -65.2592), // Sucre, Bolivia
          zoom: 15,
        ),
        markers:
            _selectedLocation != null
                ? {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selectedLocation!,
                  ),
                }
                : {},
      ),
    );
  }
}
