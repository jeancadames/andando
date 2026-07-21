import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/map_pickup_point.dart';
import '../../models/place_search_result.dart';
import '../../services/provider_experience_service.dart';
import '../../widgets/place_search_field.dart';

class LocationPickerMapScreen extends StatefulWidget {
  final String? token;
  final MapPickupPoint? initialPoint;

  const LocationPickerMapScreen({
    super.key,
    required this.token,
    this.initialPoint,
  });

  @override
  State<LocationPickerMapScreen> createState() =>
      _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen> {
  static const LatLng _santoDomingo = LatLng(18.4861, -69.9312);

  final ProviderExperienceService _service = ProviderExperienceService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  GoogleMapController? _mapController;
  late LatLng _selectedLocation;
  late LatLng _cameraTarget;
  String? _selectedPlaceId;
  bool _preservePlaceIdOnNextIdle = false;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialPoint;
    _selectedLocation = initial == null
        ? _santoDomingo
        : LatLng(initial.latitude, initial.longitude);
    _cameraTarget = _selectedLocation;
    _selectedPlaceId = initial?.placeId;
    _preservePlaceIdOnNextIdle = _selectedPlaceId?.trim().isNotEmpty == true;
    _nameController.text = initial?.name ?? '';
    _addressController.text = initial?.address ?? '';
    _instructionsController.text = initial?.instructions ?? '';
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _moveCamera(LatLng target) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack('Activa la ubicacion del dispositivo.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('No tenemos permiso para acceder a tu ubicacion.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final current = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = current;
        _cameraTarget = current;
        _selectedPlaceId = null;
        _preservePlaceIdOnNextIdle = false;
      });

      await _moveCamera(current);
    } catch (_) {
      _showSnack('No pudimos obtener tu ubicacion.');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _selectPlace(PlaceSearchResult place) async {
    final location = LatLng(place.latitude, place.longitude);

    setState(() {
      _selectedLocation = location;
      _cameraTarget = location;
      _selectedPlaceId = place.placeId;
      _preservePlaceIdOnNextIdle = true;
      _addressController.text = place.address.isNotEmpty
          ? place.address
          : place.name;

      if (_nameController.text.trim().isEmpty) {
        _nameController.text = place.name;
      }
    });

    await _moveCamera(location);
  }

  void _onCameraIdle() {
    if (!mounted) return;

    setState(() {
      _selectedLocation = _cameraTarget;

      if (_preservePlaceIdOnNextIdle) {
        _preservePlaceIdOnNextIdle = false;
      } else {
        _selectedPlaceId = null;
      }
    });
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
      _showSnack('Escribe una direccion o referencia.');
      return;
    }

    Navigator.of(context).pop(
      MapPickupPoint(
        name: name,
        address: address,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        placeId: _selectedPlaceId,
        instructions: instructions.isEmpty ? null : instructions,
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          widget.initialPoint == null
              ? 'Seleccionar punto de recogida'
              : 'Editar punto de recogida',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMove: (position) {
                    _cameraTarget = position.target;
                  },
                  onCameraIdle: _onCameraIdle,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                ),
                const IgnorePointer(
                  child: Icon(Icons.location_pin, size: 52, color: Colors.red),
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
                      hint: 'Ej: Agora Mall, Parque Colon',
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
                        labelText: 'Direccion o referencia',
                        hintText: 'Ej: Frente a la entrada principal',
                        helperText:
                            'Si mueves el mapa, ajusta la referencia si es necesario.',
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
                        label: Text(
                          widget.initialPoint == null
                              ? 'Confirmar ubicacion'
                              : 'Guardar cambios',
                        ),
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
