import 'dart:typed_data';

import '../models/map_pickup_point.dart';
import '../presentation/screens/location_picker_map_screen.dart';

import '../models/experience_location.dart';
import '../presentation/screens/experience_location_picker_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/inputs/app_select_field.dart';
import '../../../auth/application/auth_controller.dart';
import '../services/provider_experience_service.dart';

import 'package:go_router/go_router.dart';

String _durationNumberForInput(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  return match?.group(0) ?? '';
}

bool _isPositiveIntegerText(String value) {
  final number = int.tryParse(value.trim());
  return number != null && number > 0;
}

String _normalizeCancellationPolicyForInput(String value) {
  switch (value.trim()) {
    case 'flexible':
      return 'free_24h';
    case 'moderate':
      return 'free_48h';
    case 'strict':
      return 'free_72h';
    default:
      return value.trim();
  }
}

String _formatCurrencyAmount(double value, String currency) {
  final prefix = currency.toUpperCase() == 'USD' ? 'US\$' : 'RD\$';
  final rounded = value.round().toString();

  final formatted = rounded.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  return '$prefix$formatted';
}

String _formatCommissionPercentage(double rate) {
  final percentage = rate * 100;

  if (percentage == percentage.roundToDouble()) {
    return '${percentage.round()}%';
  }

  return '${percentage.toStringAsFixed(2)}%';
}

class CreateExperienceScreen extends StatefulWidget {
  final int? experienceId;
  final AuthController authController;

  const CreateExperienceScreen({
    super.key,
    this.experienceId,
    required this.authController,
  });

  bool get isEditing => experienceId != null;

  @override
  State<CreateExperienceScreen> createState() => _CreateExperienceScreenState();
}

class _CreateExperienceScreenState extends State<CreateExperienceScreen> {
  final ProviderExperienceService _service = ProviderExperienceService();
  final ImagePicker _imagePicker = ImagePicker();

  final ProviderExperienceForm _form = ProviderExperienceForm();

  int _currentStep = 1;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _pricingSettingsLoaded = false;
  String? _error;

  double _commissionRate = 0.15;

  final List<String> _categories = const [
    'Aventura',
    'Playa',
    'Cultural',
    'Naturaleza',
    'Gastronomía',
    'Deportes',
    'Wellness',
    'Historia',
    'Ecoturismo',
    'Otro',
  ];

  final List<String> _provinces = const [
    'Distrito Nacional',
    'Azua',
    'Bahoruco',
    'Barahona',
    'Dajabón',
    'Duarte',
    'El Seibo',
    'Elías Piña',
    'Espaillat',
    'Hato Mayor',
    'Hermanas Mirabal',
    'Independencia',
    'La Altagracia',
    'La Romana',
    'La Vega',
    'María Trinidad Sánchez',
    'Monseñor Nouel',
    'Monte Cristi',
    'Monte Plata',
    'Pedernales',
    'Peravia',
    'Puerto Plata',
    'Samaná',
    'San Cristóbal',
    'San José de Ocoa',
    'San Juan',
    'San Pedro de Macorís',
    'Sánchez Ramírez',
    'Santiago',
    'Santiago Rodríguez',
    'Santo Domingo',
    'Valverde',
  ];

  final List<String> _amenities = const [
    'Transporte incluido',
    'Guía certificado',
    'Almuerzo',
    'Bebidas',
    'Equipo de seguridad',
    'Seguro',
    'Fotos incluidas',
    'Wi-Fi',
  ];

  @override
  void initState() {
    super.initState();

    _loadPricingSettings();

    if (widget.isEditing) {
      _loadExperience();
    }
  }

  Future<void> _loadPricingSettings() async {
    try {
      final settings = await _service.getPricingSettings(
        token: widget.authController.token,
      );

      if (!mounted) return;

      setState(() {
        _commissionRate = settings.commissionRate;
        _pricingSettingsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _commissionRate = 0.15;
        _pricingSettingsLoaded = true;
      });
    }
  }

  Future<void> _loadExperience() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final experience = await _service.getExperience(
        id: widget.experienceId!,
        token: widget.authController.token,
      );

      if (!mounted) return;

      final loadedForm = ProviderExperienceForm.fromExperience(experience);

      setState(() {
        _form.title = loadedForm.title;
        _form.category = loadedForm.category;
        _form.description = loadedForm.description;
        _form.duration = _durationNumberForInput(loadedForm.duration);
        _form.capacity = loadedForm.capacity;
        _form.price = loadedForm.price;
        _form.currency = loadedForm.currency;
        _form.startLocation = loadedForm.startLocation;
        _form.province = loadedForm.province;
        _form.experienceAddress = loadedForm.experienceAddress;
        _form.experienceLatitude = loadedForm.experienceLatitude;
        _form.experienceLongitude = loadedForm.experienceLongitude;
        _form.pickupPoints = loadedForm.pickupPoints;
        _form.mapPickupPoints = loadedForm.mapPickupPoints;
        _form.itinerary = loadedForm.itinerary;
        _form.amenities = loadedForm.amenities;
        _form.included = loadedForm.included;
        _form.notIncluded = loadedForm.notIncluded;
        _form.requirements = loadedForm.requirements;
        _form.cancellationPolicy = _normalizeCancellationPolicyForInput(
          loadedForm.cancellationPolicy,
        );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 1:
        final durationHours = _durationNumberForInput(_form.duration);

        return _form.title.trim().isNotEmpty &&
            _form.category.trim().isNotEmpty &&
            _form.description.trim().isNotEmpty &&
            _isPositiveIntegerText(durationHours) &&
            _form.capacity > 0;

      case 2:
        return widget.isEditing || _form.photos.length >= 3;

      case 3:
        final hasPickupPoint =
            _form.pickupPoints.any((item) => item.trim().isNotEmpty) ||
                _form.mapPickupPoints.isNotEmpty;

        final hasExperienceLocation =
            _form.experienceAddress.trim().isNotEmpty &&
                _form.experienceLatitude != null &&
                _form.experienceLongitude != null;

        return _form.price > 0 &&
          _form.startLocation.trim().isNotEmpty &&
          _form.province.trim().isNotEmpty &&
          hasPickupPoint &&
          hasExperienceLocation;

      case 4:
        return _form.itinerary.length >= 2 &&
            _form.itinerary.every(
              (item) =>
                  (item['time'] ?? '').trim().isNotEmpty &&
                  (item['activity'] ?? '').trim().isNotEmpty,
            );

      case 5:
        return _form.included.any((item) => item.trim().isNotEmpty) &&
            _form.cancellationPolicy.trim().isNotEmpty;

      default:
        return false;
    }
  }

  Future<void> _pickPhotos() async {
    final List<XFile> selected = await _imagePicker.pickMultiImage(
      imageQuality: 82,
    );

    if (!mounted) return;
    if (selected.isEmpty) return;

    setState(() {
      _form.photos.addAll(selected);
    });
  }

  Future<void> _confirmPublish() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return _PublishPriceConfirmationSheet(
          price: _form.price,
          currency: _form.currency,
          commissionRate: _commissionRate,
          pricingSettingsLoaded: _pricingSettingsLoaded,
        );
      },
    );

    if (!mounted) return;

    if (action == 'edit_price') {
      setState(() {
        _currentStep = 3;
      });
      return;
    }

    if (action == 'publish') {
      await _save(publish: true);
    }
  }

  void _syncLegacyPickupPointsFromMapPoints() {
    if (_form.mapPickupPoints.isEmpty) return;

    _form.pickupPoints = _form.mapPickupPoints
        .map((point) {
          final name = point.name.trim();
          final address = point.address.trim();

          if (name.isNotEmpty) return name;
          if (address.isNotEmpty) return address;

          return 'Punto de recogida';
        })
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  Future<void> _save({required bool publish}) async {
    setState(() {
      _isSaving = true;
    });

    try {
      _form.duration = _durationNumberForInput(_form.duration);
      _syncLegacyPickupPointsFromMapPoints();

      await _service.saveExperience(
        form: _form,
        token: widget.authController.token,
        experienceId: widget.experienceId,
        publish: publish,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publish
                ? 'Experiencia publicada correctamente.'
                : 'Borrador guardado correctamente.',
          ),
        ),
      );

      final navigator = Navigator.of(context);

      if (navigator.canPop()) {
        navigator.pop(true);
        return;
      }

      context.go('/provider/catalog');
      return;
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  void _next() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _back() async {
    if (_currentStep > 1) {
      if (!mounted) return;

      setState(() {
        _currentStep--;
      });

      return;
    }

    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop(false);
      return;
    }

    if (!mounted) return;

    context.go('/provider/dashboard');
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_form.amenities.contains(amenity)) {
        _form.amenities.remove(amenity);
      } else {
        _form.amenities.add(amenity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.isEditing ? 'Editar experiencia' : 'Nueva experiencia',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(publish: false),
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!.replaceFirst('Exception: ', '')))
              : Column(
                  children: [
                    _ProgressHeader(currentStep: _currentStep),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildStep(),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: FilledButton(
            onPressed: _isSaving || !_canProceed()
                ? null
                : () {
                    if (_currentStep == 5) {
                      _confirmPublish();
                    } else {
                      _next();
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _isSaving
                    ? 'Guardando...'
                    : _currentStep == 5
                        ? 'Publicar experiencia'
                        : 'Continuar',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return _BasicInfoStep(
          form: _form,
          categories: _categories,
          onChanged: () => setState(() {}),
        );

      case 2:
        return _PhotosStep(
          photos: _form.photos,
          onPickPhotos: _pickPhotos,
          onRemove: (index) {
            setState(() {
              _form.photos.removeAt(index);
            });
          },
        );

      case 3:
        return _PriceLocationStep(
          form: _form,
          provinces: _provinces,
          commissionRate: _commissionRate,
          pricingSettingsLoaded: _pricingSettingsLoaded,
          token: widget.authController.token,
          onChanged: () => setState(() {}),
        );

      case 4:
        return _ItineraryStep(
          form: _form,
          onChanged: () => setState(() {}),
        );

      case 5:
        return _RulesStep(
          form: _form,
          amenities: _amenities,
          onToggleAmenity: _toggleAmenity,
          onChanged: () => setState(() {}),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProgressHeader extends StatelessWidget {
  final int currentStep;

  const _ProgressHeader({
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        children: [
          Text(
            'Paso $currentStep de 5',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final step = index + 1;

              return Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: step <= currentStep
                        ? primary
                        : const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  final ProviderExperienceForm form;
  final List<String> categories;
  final VoidCallback onChanged;

  const _BasicInfoStep({
    required this.form,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepContainer(
      title: 'Información básica',
      subtitle: 'Cuéntanos sobre tu experiencia',
      children: [
        _Input(
          label: 'Nombre de la experiencia *',
          initialValue: form.title,
          hint: 'Ej: Aventura en Samaná',
          onChanged: (value) {
            form.title = value;
            onChanged();
          },
        ),
        _DropdownInput(
          label: 'Categoría *',
          value: form.category.isEmpty ? null : form.category,
          items: categories,
          onChanged: (value) {
            form.category = value ?? '';
            onChanged();
          },
        ),
        _Input(
          label: 'Descripción *',
          initialValue: form.description,
          hint: 'Describe qué harán los viajeros...',
          maxLines: 5,
          onChanged: (value) {
            form.description = value;
            onChanged();
          },
        ),
        Row(
          children: [
            Expanded(
              child: _Input(
                label: 'Duración *',
                initialValue: _durationNumberForInput(form.duration),
                hint: '8',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                suffixText: 'horas',
                onChanged: (value) {
                  form.duration = value.trim();
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Input(
                label: 'Capacidad *',
                initialValue: form.capacity <= 0 ? '' : form.capacity.toString(),
                hint: '15',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  form.capacity = int.tryParse(value) ?? 0;
                  onChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotosStep extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onRemove;

  const _PhotosStep({
    required this.photos,
    required this.onPickPhotos,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _StepContainer(
      title: 'Fotos',
      subtitle: 'Mínimo 3 fotos. La primera será la portada.',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Sube fotos claras y atractivas. Esto impacta directamente la conversión.',
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            if (index == photos.length) {
              return InkWell(
                onTap: onPickPhotos,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload),
                      SizedBox(height: 8),
                      Text('Subir foto'),
                    ],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _SelectedPhotoPreview(
                      photo: photos[index],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.red,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      onTap: () => onRemove(index),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.delete_outline,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Portada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SelectedPhotoPreview extends StatelessWidget {
  const _SelectedPhotoPreview({
    required this.photo,
  });

  final XFile photo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: photo.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: const Color(0xFFE5E7EB),
            child: const Center(
              child: Icon(Icons.broken_image_outlined),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            color: const Color(0xFFE5E7EB),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Image.memory(
          snapshot.data!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _PriceLocationStep extends StatelessWidget {
  final ProviderExperienceForm form;
  final List<String> provinces;
  final double commissionRate;
  final bool pricingSettingsLoaded;
  final String? token;
  final VoidCallback onChanged;

  const _PriceLocationStep({
    required this.form,
    required this.provinces,
    required this.commissionRate,
    required this.pricingSettingsLoaded,
    required this.token,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepContainer(
      title: 'Precios y ubicación',
      subtitle: 'Define dónde inicia y los puntos de recogida.',
      children: [
        _Input(
          label: 'Precio por persona *',
          initialValue: form.price == 0 ? '' : form.price.toStringAsFixed(0),
          hint: '3500',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.attach_money,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            form.price = double.tryParse(value) ?? 0;
            onChanged();
          },
        ),
        _PriceBreakdownCard(
          price: form.price,
          currency: form.currency,
          commissionRate: commissionRate,
          pricingSettingsLoaded: pricingSettingsLoaded,
        ),
        _Input(
          label: 'Punto de partida general *',
          initialValue: form.startLocation,
          hint: 'Ej: Zona Colonial, Santo Domingo',
          maxLines: 3,
          prefixIcon: Icons.location_on,
          onChanged: (value) {
            form.startLocation = value;
            onChanged();
          },
        ),
        _DropdownInput(
          label: 'Provincia *',
          value: form.province.isEmpty ? null : form.province,
          items: provinces,
          onChanged: (value) {
            form.province = value ?? '';
            onChanged();
          },
        ),
        _ExperienceLocationSection(
          form: form,
          token: token,
          onChanged: onChanged,
        ),
        _PickupPointsSection(
          form: form,
          token: token,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ExperienceLocationSection extends StatelessWidget {
  final ProviderExperienceForm form;
  final String? token;
  final VoidCallback onChanged;

  const _ExperienceLocationSection({
    required this.form,
    required this.token,
    required this.onChanged,
  });

  bool get hasLocation =>
      form.experienceAddress.trim().isNotEmpty &&
      form.experienceLatitude != null &&
      form.experienceLongitude != null;

  Future<void> _openLocationPicker(BuildContext context) async {
    final location = await Navigator.of(context).push<ExperienceLocation>(
      MaterialPageRoute(
        builder: (_) => ExperienceLocationPickerScreen(
          token: token,
        ),
      ),
    );

    if (location == null) return;

    form.experienceAddress = location.address;
    form.experienceLatitude = location.latitude;
    form.experienceLongitude = location.longitude;

    onChanged();
  }

  void _clearLocation() {
    form.experienceAddress = '';
    form.experienceLatitude = null;
    form.experienceLongitude = null;

    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación de la experiencia *',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Esta ubicación se usará para mostrar experiencias cerca del cliente.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openLocationPicker(context),
            icon: const Icon(Icons.place_outlined),
            label: Text(
              hasLocation
                  ? 'Cambiar ubicación de la experiencia'
                  : 'Seleccionar ubicación de la experiencia',
            ),
          ),
        ),
        if (hasLocation) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.experienceAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${form.experienceLatitude!.toStringAsFixed(6)}, '
                        '${form.experienceLongitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _clearLocation,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PickupPointsSection extends StatelessWidget {
  final ProviderExperienceForm form;
  final String? token;
  final VoidCallback onChanged;

  const _PickupPointsSection({
    required this.form,
    required this.token,
    required this.onChanged,
  });

  Future<void> _openMapPicker(BuildContext context) async {
    final point = await Navigator.of(context).push<MapPickupPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerMapScreen(
          token: token,
        ),
      ),
    );

    if (point == null) return;

    form.mapPickupPoints.add(point);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditableStringList(
          label: 'Puntos de recogida manuales *',
          items: form.pickupPoints,
          hint: 'Ej: Agora Mall',
          onChanged: onChanged,
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openMapPicker(context),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Seleccionar punto en mapa'),
          ),
        ),

        if (form.mapPickupPoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Puntos seleccionados en mapa',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          ...List.generate(form.mapPickupPoints.length, (index) {
            final point = form.mapPickupPoints[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_pin, color: Colors.red),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          point.address,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        if (point.instructions != null &&
                            point.instructions!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            point.instructions!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      form.mapPickupPoints.removeAt(index);
                      onChanged();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _PriceBreakdownCard extends StatelessWidget {
  final double price;
  final String currency;
  final double commissionRate;
  final bool pricingSettingsLoaded;

  const _PriceBreakdownCard({
    required this.price,
    required this.currency,
    required this.commissionRate,
    required this.pricingSettingsLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final platformFee = price * commissionRate;
    final providerAmount = price - platformFee;
    final percentageLabel = _formatCommissionPercentage(commissionRate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Desglose transparente',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pricingSettingsLoaded
                ? 'La comisión de AndanDO es de $percentageLabel por reserva confirmada.'
                : 'Cargando configuración de comisión...',
            style: const TextStyle(
              color: Colors.black54,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (price <= 0)
            const Text(
              'Ingresa un precio para ver cuánto recibes por persona.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            )
          else ...[
            _BreakdownRow(
              label: 'Cliente paga',
              value: _formatCurrencyAmount(price, currency),
              isStrong: true,
            ),
            const SizedBox(height: 8),
            _BreakdownRow(
              label: 'AndanDO recibe',
              value: _formatCurrencyAmount(platformFee, currency),
            ),
            const SizedBox(height: 8),
            _BreakdownRow(
              label: 'Tú recibes',
              value: _formatCurrencyAmount(providerAmount, currency),
              isStrong: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStrong;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: isStrong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PublishPriceConfirmationSheet extends StatelessWidget {
  final double price;
  final String currency;
  final double commissionRate;
  final bool pricingSettingsLoaded;

  const _PublishPriceConfirmationSheet({
    required this.price,
    required this.currency,
    required this.commissionRate,
    required this.pricingSettingsLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.price_check_outlined,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Antes de publicar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Confirma que este será el desglose por persona para esta experiencia.',
              style: TextStyle(
                color: Colors.black54,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            _PriceBreakdownCard(
              price: price,
              currency: currency,
              commissionRate: commissionRate,
              pricingSettingsLoaded: pricingSettingsLoaded,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop('edit_price');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('Modificar precio'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop('publish');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('Publicar'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryStep extends StatelessWidget {
  final ProviderExperienceForm form;
  final VoidCallback onChanged;

  const _ItineraryStep({
    required this.form,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepContainer(
      title: 'Itinerario',
      subtitle: 'Describe el día paso a paso.',
      children: [
        ...List.generate(form.itinerary.length, (index) {
          final item = form.itinerary[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E9E9)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Paso ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (form.itinerary.length > 1)
                      IconButton(
                        onPressed: () {
                          form.itinerary.removeAt(index);
                          onChanged();
                        },
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _ItineraryTimePickerField(
                  value: item['time'] ?? '',
                  onChanged: (value) {
                    item['time'] = value;
                    onChanged();
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: item['activity'] ?? '',
                  decoration: InputDecoration(
                    labelText: 'Actividad *',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onChanged: (value) {
                    item['activity'] = value;
                    onChanged();
                  },
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            form.itinerary.add({'time': '', 'activity': ''});
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar paso'),
        ),
      ],
    );
  }
}

class _ItineraryTimePickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ItineraryTimePickerField({
    required this.value,
    required this.onChanged,
  });

  TimeOfDay _initialTimeFromValue(String value) {
    final normalized = value.trim().toUpperCase();

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
    ).firstMatch(normalized);

    if (match == null) {
      return const TimeOfDay(hour: 8, minute: 0);
    }

    var hour = int.tryParse(match.group(1) ?? '') ?? 8;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = match.group(3);

    if (period == 'PM' && hour < 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return const TimeOfDay(hour: 8, minute: 0);
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour12:$minute $period';
  }

  Future<void> _pickTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _initialTimeFromValue(value),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selected == null) return;

    onChanged(_formatTime(selected));
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hora *',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          hasValue ? value : 'Seleccionar hora',
          style: TextStyle(
            color: hasValue ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _RulesStep extends StatelessWidget {
  final ProviderExperienceForm form;
  final List<String> amenities;
  final ValueChanged<String> onToggleAmenity;
  final VoidCallback onChanged;

  const _RulesStep({
    required this.form,
    required this.amenities,
    required this.onToggleAmenity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepContainer(
      title: 'Amenidades y reglas',
      subtitle: 'Últimos detalles importantes.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final selected = form.amenities.contains(amenity);

            return FilterChip(
              selected: selected,
              label: Text(amenity),
              onSelected: (_) => onToggleAmenity(amenity),
            );
          }).toList(),
        ),
        _EditableStringList(
          label: 'Qué incluye *',
          items: form.included,
          hint: 'Ej: Almuerzo típico dominicano',
          onChanged: onChanged,
        ),
        _EditableStringList(
          label: 'Qué NO incluye',
          items: form.notIncluded,
          hint: 'Ej: Propinas',
          onChanged: onChanged,
        ),
        _EditableStringList(
          label: 'Requisitos',
          items: form.requirements,
          hint: 'Ej: Ropa cómoda',
          onChanged: onChanged,
        ),
        _DropdownInput(
          label: 'Política de cancelación *',
          value:
              form.cancellationPolicy.isEmpty ? null : form.cancellationPolicy,
          items: const [
            'free_24h',
            'free_48h',
            'free_72h',
            'free_5d',
            'no-refund',
          ],
          labels: const {
            'free_24h': 'Cancelación gratis hasta 24 horas antes',
            'free_48h': 'Cancelación gratis hasta 48 horas antes',
            'free_72h': 'Cancelación gratis hasta 72 horas antes',
            'free_5d': 'Cancelación gratis hasta 5 días antes',
            'no-refund': 'Sin reembolso',
          },
          onChanged: (value) {
            form.cancellationPolicy = value ?? '';
            onChanged();
          },
        ),
      ],
    );
  }
}

class _StepContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _StepContainer({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final String initialValue;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;

  const _Input({
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.suffixText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixText: suffixText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _DropdownInput extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Map<String, String>? labels;
  final ValueChanged<String?> onChanged;

  const _DropdownInput({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final optionExists = value != null && items.contains(value);
    final selectedValue = optionExists ? value! : '';

    return AppSelectField(
      label: label,
      value: selectedValue,
      placeholder: 'Seleccionar...',
      options: items.map((item) {
        return AppSelectOption(
          value: item,
          label: labels?[item] ?? item,
        );
      }).toList(),
      onChanged: onChanged,
      height: 56,
      maxMenuHeight: 320,
    );
  }
}

class _EditableStringList extends StatelessWidget {
  final String label;
  final List<String> items;
  final String hint;
  final VoidCallback onChanged;

  const _EditableStringList({
    required this.label,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      items.add('');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...List.generate(items.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: items[index],
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (value) {
                      items[index] = value;
                      onChanged();
                    },
                  ),
                ),
                if (items.length > 1)
                  IconButton(
                    onPressed: () {
                      items.removeAt(index);
                      onChanged();
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            items.add('');
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar más'),
        ),
      ],
    );
  }
}

