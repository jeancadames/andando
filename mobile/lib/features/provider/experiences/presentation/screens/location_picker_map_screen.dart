import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/map_pickup_point.dart';
import '../../models/place_search_result.dart';
import '../../services/provider_experience_service.dart';
import '../../widgets/place_search_field.dart';

class LocationPickerMapScreen extends StatefulWidget {
  final String? token;

  const LocationPickerMapScreen({
    super.key,
    required this.token,
  });

  @override
  State<LocationPickerMapScreen> createState() =>
      _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen> {
  final MapController _mapController = MapController();
  final ProviderExperienceService _service = ProviderExperienceService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  LatLng _selectedLocation = const LatLng(18.4861, -69.9312);
  bool _loadingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack('Activa la ubicación del dispositivo.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('No tenemos permiso para acceder a tu ubicación.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = current;
      });

      _mapController.move(current, 16);
    } catch (_) {
      _showSnack('No pudimos obtener tu ubicación.');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  void _selectPlace(PlaceSearchResult place) {
    final location = LatLng(place.latitude, place.longitude);

    setState(() {
      _selectedLocation = location;

      _addressController.text =
          place.address.isNotEmpty ? place.address : place.name;

      if (_nameController.text.trim().isEmpty) {
        _nameController.text = place.name;
      }
    });

    _mapController.move(location, 16);
  }

  void _confirmLocation() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final instructions = _instructionsController.text.trim();

    if (name.isEmpty) {
      _showSnack('Escribe un nombre para el punto de recogida.');
      return;
    }

    if (address.isEmpty) {
      _showSnack('Escribe una dirección o referencia.');
      return;
    }

    Navigator.of(context).pop(
      MapPickupPoint(
        name: name,
        address: address,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        instructions: instructions.isEmpty ? null : instructions,
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Seleccionar punto de recogida'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 14,
                    onPositionChanged: (position, hasGesture) {
                      final center = position.center;

                      setState(() {
                        _selectedLocation = center;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.andando.app',
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Icon(
                    Icons.location_pin,
                    size: 52,
                    color: Colors.red,
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'current-location-btn',
                    onPressed: _loadingLocation ? null : _goToCurrentLocation,
                    child: _loadingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, -2),
                  color: Color(0x1A000000),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)} | '
                      'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),

                    PlaceSearchField(
                      service: _service,
                      token: widget.token,
                      label: 'Buscar punto de recogida',
                      hint: 'Ej: Agora Mall, Parque Colón',
                      onSelected: _selectPlace,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del punto',
                        hintText: 'Ej: Parque Central',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección o referencia',
                        hintText: 'Ej: Frente a la entrada principal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _instructionsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Instrucciones opcionales',
                        hintText: 'Ej: Llegar 15 minutos antes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmLocation,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar ubicación'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}