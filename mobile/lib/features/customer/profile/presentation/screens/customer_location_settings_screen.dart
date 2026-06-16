import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/customer_location_preferences_service.dart';

class CustomerLocationSettingsScreen extends StatefulWidget {
  const CustomerLocationSettingsScreen({super.key});

  @override
  State<CustomerLocationSettingsScreen> createState() =>
      _CustomerLocationSettingsScreenState();
}

class _CustomerLocationSettingsScreenState
    extends State<CustomerLocationSettingsScreen> {
  final CustomerLocationPreferencesService _preferencesService =
      CustomerLocationPreferencesService();

  bool _isLoading = true;
  bool _isSaving = false;

  bool _gpsEnabled = true;
  bool _autoDetectEnabled = false;
  int _radiusKm = 50;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final gpsEnabled = await _preferencesService.getGpsEnabled();
    final autoDetectEnabled = await _preferencesService.getAutoDetectEnabled();
    final radiusKm = await _preferencesService.getSearchRadiusKm();

    if (!mounted) return;

    setState(() {
      _gpsEnabled = gpsEnabled;
      _autoDetectEnabled = autoDetectEnabled;
      _radiusKm = radiusKm;
      _isLoading = false;
    });
  }

  Future<void> _toggleGps(bool value) async {
    if (!value) {
      setState(() {
        _gpsEnabled = false;
        _autoDetectEnabled = false;
      });
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa el GPS del dispositivo para usar esta opción.'),
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tenemos permiso para acceder a tu ubicación.'),
        ),
      );
      return;
    }

    setState(() {
      _gpsEnabled = true;
    });
  }

  void _toggleAutoDetect(bool value) {
    if (value && !_gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero activa el GPS del dispositivo.'),
        ),
      );
      return;
    }

    setState(() {
      _autoDetectEnabled = value;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    await _preferencesService.save(
      gpsEnabled: _gpsEnabled,
      autoDetectEnabled: _autoDetectEnabled,
      searchRadiusKm: _radiusKm,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ubicación guardada correctamente.'),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicación',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Personaliza tu experiencia por región',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                const _SectionTitle('Permisos de Ubicación'),
                _SettingsCard(
                  children: [
                    _SwitchRow(
                      icon: Icons.navigation_outlined,
                      iconBackground: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF003B73),
                      title: 'GPS del dispositivo',
                      subtitle: 'Usar ubicación en tiempo real',
                      value: _gpsEnabled,
                      onChanged: _toggleGps,
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _SwitchRow(
                      icon: Icons.public_rounded,
                      iconBackground: const Color(0xFFF3F4F6),
                      iconColor: const Color(0xFF6B7280),
                      title: 'Detectar automáticamente',
                      subtitle: 'Al abrir la aplicación',
                      value: _autoDetectEnabled,
                      onChanged: _toggleAutoDetect,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Radio de Búsqueda'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Mostrar experiencias en un radio de',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Text(
                            '$_radiusKm km',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF003B73),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        min: 10,
                        max: 200,
                        divisions: 19,
                        value: _radiusKm.toDouble(),
                        activeColor: const Color(0xFF003B73),
                        onChanged: (value) {
                          setState(() {
                            _radiusKm = value.round();
                          });
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '10 km',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '200 km',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003B73),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Guardando...' : 'Guardar Ubicación',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xFF003B73),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFE5E7EB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8A94A6),
        ),
      ),
    );
  }
}