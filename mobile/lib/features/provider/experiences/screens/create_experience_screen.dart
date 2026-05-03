import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/application/auth_controller.dart';
import '../services/provider_experience_service.dart';

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
  String? _error;

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
    'Santo Domingo',
    'Santiago',
    'La Vega',
    'Puerto Plata',
    'San Cristóbal',
    'Duarte',
    'La Altagracia',
    'San Pedro de Macorís',
    'Espaillat',
    'Samaná',
    'Barahona',
    'Pedernales',
    'Monte Plata',
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

    if (widget.isEditing) {
      _loadExperience();
    }
  }

  Future<void> _loadExperience() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final experience = await _service.getExperience(
        id: widget.experienceId!,
        token: widget.authController.token,
      );

      final loadedForm = ProviderExperienceForm.fromExperience(experience);

      setState(() {
        _form.title = loadedForm.title;
        _form.category = loadedForm.category;
        _form.description = loadedForm.description;
        _form.duration = loadedForm.duration;
        _form.capacity = loadedForm.capacity;
        _form.price = loadedForm.price;
        _form.currency = loadedForm.currency;
        _form.startLocation = loadedForm.startLocation;
        _form.province = loadedForm.province;
        _form.pickupPoints = loadedForm.pickupPoints;
        _form.itinerary = loadedForm.itinerary;
        _form.amenities = loadedForm.amenities;
        _form.included = loadedForm.included;
        _form.notIncluded = loadedForm.notIncluded;
        _form.requirements = loadedForm.requirements;
        _form.cancellationPolicy = loadedForm.cancellationPolicy;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 1:
        return _form.title.trim().isNotEmpty &&
            _form.category.trim().isNotEmpty &&
            _form.description.trim().isNotEmpty &&
            _form.duration.trim().isNotEmpty &&
            _form.capacity > 0;
      case 2:
        return widget.isEditing || _form.photos.length >= 3;
      case 3:
        return _form.price > 0 &&
            _form.startLocation.trim().isNotEmpty &&
            _form.province.trim().isNotEmpty &&
            _form.pickupPoints.any((item) => item.trim().isNotEmpty);
      case 4:
        return _form.itinerary.length >= 2 &&
            _form.itinerary.every(
              (item) =>
                  item['time']!.trim().isNotEmpty &&
                  item['activity']!.trim().isNotEmpty,
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

    if (selected.isEmpty) return;

    setState(() {
      _form.photos.addAll(selected);
    });
  }

  Future<void> _save({required bool publish}) async {
    setState(() {
      _isSaving = true;
    });

    try {
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

      Navigator.pop(context, true);
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

  void _back() {
    if (_currentStep == 1) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep--;
    });
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
                      _save(publish: true);
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
                initialValue: form.duration,
                hint: 'Ej: 8 horas',
                onChanged: (value) {
                  form.duration = value;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Input(
                label: 'Capacidad *',
                initialValue: form.capacity.toString(),
                hint: '15',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  form.capacity = int.tryParse(value) ?? 1;
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
            color: Colors.blue.withValues(alpha: 0.08),
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
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onRemove(index),
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
  final VoidCallback onChanged;

  const _PriceLocationStep({
    required this.form,
    required this.provinces,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepContainer(
      title: 'Precios y ubicación',
      subtitle: 'Define dónde inicia y cuánto cuesta.',
      children: [
        _Input(
          label: 'Precio por persona *',
          initialValue: form.price == 0 ? '' : form.price.toStringAsFixed(0),
          hint: '3500',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.attach_money,
          onChanged: (value) {
            form.price = double.tryParse(value) ?? 0;
            onChanged();
          },
        ),
        _Input(
          label: 'Punto de partida *',
          initialValue: form.startLocation,
          hint: 'Dirección exacta del punto de partida',
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
        _EditableStringList(
          label: 'Puntos de recogida *',
          items: form.pickupPoints,
          hint: 'Ej: Agora Mall',
          onChanged: onChanged,
        ),
      ],
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
                TextFormField(
                  initialValue: item['time'],
                  decoration: const InputDecoration(labelText: 'Hora'),
                  onChanged: (value) {
                    item['time'] = value;
                    onChanged();
                  },
                ),
                TextFormField(
                  initialValue: item['activity'],
                  decoration: const InputDecoration(labelText: 'Actividad'),
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
            'flexible',
            'moderate',
            'strict',
            'no-refund',
          ],
          labels: const {
            'flexible': 'Flexible',
            'moderate': 'Moderada',
            'strict': 'Estricta',
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
  final ValueChanged<String> onChanged;

  const _Input({
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
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
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(labels?[item] ?? item),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
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