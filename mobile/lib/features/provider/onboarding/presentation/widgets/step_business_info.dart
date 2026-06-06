import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'provider_text_field.dart';

/// Paso 2 del registro de afiliado.
///
/// Esta pantalla recoge la información comercial del afiliado:
/// - Nombre del negocio.
/// - Tipo de negocio.
/// - RNC.
/// - Dirección.
/// - Ciudad.
/// - Provincia.
///
/// Importante:
/// El campo "Tipo de negocio" envía un slug técnico al backend.
///
/// Flutter enviará uno de estos valores:
///
/// - tourism_agency
/// - tour_operator
/// - tour_guide
/// - tourism_transport
/// - activities_experiences
/// - other
///
/// Laravel debe tener esos mismos slugs registrados en la tabla:
///
/// provider_business_types
///
/// Si backend no tiene esos slugs, Laravel responderá:
///
/// The selected business type slug is invalid.
class StepBusinessInfo extends StatelessWidget {
  const StepBusinessInfo({
    super.key,
    required this.businessNameController,
    required this.rncController,
    required this.addressController,
    required this.cityController,
    required this.selectedBusinessTypeSlug,
    required this.selectedProvince,
    required this.onBusinessTypeChanged,
    required this.onProvinceChanged,
    required this.onChanged,
  });

  /// Controlador del nombre del negocio.
  final TextEditingController businessNameController;

  /// Controlador del RNC.
  final TextEditingController rncController;

  /// Controlador de la dirección.
  final TextEditingController addressController;

  /// Controlador de la ciudad.
  final TextEditingController cityController;

  /// Slug del tipo de negocio seleccionado.
  ///
  /// Este valor viene desde ProviderRegisterScreen y se guarda
  /// dentro de ProviderRegisterFormData.
  final String selectedBusinessTypeSlug;

  /// Provincia seleccionada.
  final String selectedProvince;

  /// Callback cuando cambia el tipo de negocio.
  final ValueChanged<String?> onBusinessTypeChanged;

  /// Callback cuando cambia la provincia.
  final ValueChanged<String?> onProvinceChanged;

  /// Callback cuando cambia cualquier campo de texto.
  final VoidCallback onChanged;

  /// Lista completa de tipos de negocio disponibles.
  ///
  /// Estos valores deben coincidir con los slugs existentes en Laravel.
  ///
  /// Backend debe aceptar:
  ///
  /// tourism_agency
  /// tour_operator
  /// tour_guide
  /// tourism_transport
  /// activities_experiences
  /// other
  static const List<_SelectOption> _businessTypes = [
    _SelectOption(
      value: 'tourism_agency',
      label: 'Agencia de Turismo',
    ),
    _SelectOption(
      value: 'tour_operator',
      label: 'Tour Operador',
    ),
    _SelectOption(
      value: 'tour_guide',
      label: 'Guía Turístico',
    ),
    _SelectOption(
      value: 'tourism_transport',
      label: 'Transporte Turístico',
    ),
    _SelectOption(
      value: 'activities_experiences',
      label: 'Actividades y Experiencias',
    ),
    _SelectOption(
      value: 'other',
      label: 'Otro',
    ),
  ];

  /// Provincias de República Dominicana + Distrito Nacional.
  ///
  /// Para el MVP dejamos una lista local.
  /// Más adelante esto puede venir desde backend.
  static const List<_SelectOption> _provinces = [
    _SelectOption(value: 'Distrito Nacional', label: 'Distrito Nacional'),
    _SelectOption(value: 'Azua', label: 'Azua'),
    _SelectOption(value: 'Bahoruco', label: 'Bahoruco'),
    _SelectOption(value: 'Barahona', label: 'Barahona'),
    _SelectOption(value: 'Dajabón', label: 'Dajabón'),
    _SelectOption(value: 'Duarte', label: 'Duarte'),
    _SelectOption(value: 'El Seibo', label: 'El Seibo'),
    _SelectOption(value: 'Elías Piña', label: 'Elías Piña'),
    _SelectOption(value: 'Espaillat', label: 'Espaillat'),
    _SelectOption(value: 'Hato Mayor', label: 'Hato Mayor'),
    _SelectOption(value: 'Hermanas Mirabal', label: 'Hermanas Mirabal'),
    _SelectOption(value: 'Independencia', label: 'Independencia'),
    _SelectOption(value: 'La Altagracia', label: 'La Altagracia'),
    _SelectOption(value: 'La Romana', label: 'La Romana'),
    _SelectOption(value: 'La Vega', label: 'La Vega'),
    _SelectOption(
      value: 'María Trinidad Sánchez',
      label: 'María Trinidad Sánchez',
    ),
    _SelectOption(value: 'Monseñor Nouel', label: 'Monseñor Nouel'),
    _SelectOption(value: 'Monte Cristi', label: 'Monte Cristi'),
    _SelectOption(value: 'Monte Plata', label: 'Monte Plata'),
    _SelectOption(value: 'Pedernales', label: 'Pedernales'),
    _SelectOption(value: 'Peravia', label: 'Peravia'),
    _SelectOption(value: 'Puerto Plata', label: 'Puerto Plata'),
    _SelectOption(value: 'Samaná', label: 'Samaná'),
    _SelectOption(value: 'San Cristóbal', label: 'San Cristóbal'),
    _SelectOption(value: 'San José de Ocoa', label: 'San José de Ocoa'),
    _SelectOption(value: 'San Juan', label: 'San Juan'),
    _SelectOption(
      value: 'San Pedro de Macorís',
      label: 'San Pedro de Macorís',
    ),
    _SelectOption(value: 'Sánchez Ramírez', label: 'Sánchez Ramírez'),
    _SelectOption(value: 'Santiago', label: 'Santiago'),
    _SelectOption(
      value: 'Santiago Rodríguez',
      label: 'Santiago Rodríguez',
    ),
    _SelectOption(value: 'Santo Domingo', label: 'Santo Domingo'),
    _SelectOption(value: 'Valverde', label: 'Valverde'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Negocio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Cuéntanos sobre tu empresa',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),

        const SizedBox(height: 28),

        ProviderTextField(
          label: 'Nombre del negocio',
          controller: businessNameController,
          hintText: 'Tours Paradise RD',
          prefixIcon: Icons.business_outlined,
          keyboardType: TextInputType.text,
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),

        _StepSelectField(
          label: 'Tipo de negocio',
          value: selectedBusinessTypeSlug,
          placeholder: 'Seleccionar...',
          options: _businessTypes,
          onChanged: onBusinessTypeChanged,
        ),

        const SizedBox(height: 20),

        ProviderTextField(
          label: 'RNC (Registro Nacional de Contribuyente)',
          controller: rncController,
          hintText: '000-00000-0',
          prefixIcon: Icons.credit_card_outlined,
          keyboardType: TextInputType.text,
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),

        ProviderTextField(
          label: 'Dirección',
          controller: addressController,
          hintText: 'Calle, número, sector',
          prefixIcon: Icons.location_on_outlined,
          keyboardType: TextInputType.streetAddress,
          maxLines: 3,
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProviderTextField(
                label: 'Ciudad',
                controller: cityController,
                hintText: 'Santo Domingo',
                prefixIcon: Icons.location_city_outlined,
                keyboardType: TextInputType.text,
                onChanged: onChanged,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _StepSelectField(
                label: 'Provincia',
                value: selectedProvince,
                placeholder: 'Seleccionar...',
                options: _provinces,
                onChanged: onProvinceChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Modelo simple para opciones de dropdown.
///
/// value:
/// Valor técnico que se guarda o se envía al backend.
///
/// label:
/// Texto visible para el usuario.
class _SelectOption {
  const _SelectOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

/// Dropdown reutilizable dentro del paso de negocio.
///
/// Lo usamos para:
/// - Tipo de negocio.
/// - Provincia.
///
/// Este widget también protege contra valores viejos.
/// Por ejemplo, si antes tenías guardado:
///
/// agencia-de-tours
///
/// pero ahora la lista usa:
///
/// tourism_agency
///
/// entonces no intentamos mostrar un value inexistente.
/// En su lugar, mostramos el placeholder "Seleccionar...".
class _StepSelectField extends StatefulWidget {
  const _StepSelectField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String placeholder;
  final List<_SelectOption> options;
  final ValueChanged<String?> onChanged;

  @override
  State<_StepSelectField> createState() => _StepSelectFieldState();
}

class _StepSelectFieldState extends State<_StepSelectField> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  static const double _fieldHeight = 52;
  static const double _itemHeight = 44;
  static const double _gap = 6;
  static const double _maxMenuHeight = 320;
  static const double _minUsableMenuHeight = 120;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final fieldSize = renderBox.size;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;

    final availableAbove = fieldOffset.dy - safeTop - _gap;
    final availableBelow = screenHeight -
        fieldOffset.dy -
        fieldSize.height -
        safeBottom -
        _gap;

    final desiredHeight = (widget.options.length * _itemHeight).clamp(
      _minUsableMenuHeight,
      _maxMenuHeight,
    );

    final shouldOpenBelow =
        availableBelow >= desiredHeight || availableBelow >= availableAbove;

    final availableSpace = shouldOpenBelow ? availableBelow : availableAbove;

    final menuHeight = desiredHeight.clamp(
      _minUsableMenuHeight,
      availableSpace <= 0 ? _minUsableMenuHeight : availableSpace,
    );

    final verticalOffset = shouldOpenBelow
        ? fieldSize.height + _gap
        : -menuHeight - _gap;

    setState(() {
      _isOpen = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),

            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, verticalOffset),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: fieldSize.width,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: menuHeight.toDouble(),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: widget.options.length,
                        itemBuilder: (context, index) {
                          final option = widget.options[index];
                          final isSelected = option.value == widget.value;

                          return InkWell(
                            onTap: () {
                              widget.onChanged(option.value);
                              _removeOverlay();
                            },
                            child: Container(
                              height: _itemHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: Alignment.centerLeft,
                              color: isSelected
                                  ? AppColors.primaryBlue.withOpacity(0.08)
                                  : Colors.transparent,
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.textDark,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final optionExists = widget.options.any(
      (option) => option.value == widget.value,
    );

    final selectedValue =
        widget.value.isEmpty || !optionExists ? null : widget.value;

    final selectedOption = selectedValue == null
        ? null
        : widget.options.firstWhere(
            (option) => option.value == selectedValue,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _fieldKey,
            behavior: HitTestBehavior.opaque,
            onTap: _toggleDropdown,
            child: Container(
              height: _fieldHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOpen
                      ? AppColors.primaryBlue
                      : const Color(0xFFE5E7EB),
                  width: _isOpen ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedOption?.label ?? widget.placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedOption == null
                            ? const Color(0xFF8A94A6)
                            : AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}