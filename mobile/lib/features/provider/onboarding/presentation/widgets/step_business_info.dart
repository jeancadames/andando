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

  /// Provincias disponibles.
  ///
  /// Para el MVP dejamos una lista local.
  /// Más adelante esto puede venir desde backend.
  static const List<_SelectOption> _provinces = [
    _SelectOption(value: 'Distrito Nacional', label: 'Distrito Nacional'),
    _SelectOption(value: 'Santo Domingo', label: 'Santo Domingo'),
    _SelectOption(value: 'Santiago', label: 'Santiago'),
    _SelectOption(value: 'La Vega', label: 'La Vega'),
    _SelectOption(value: 'Puerto Plata', label: 'Puerto Plata'),
    _SelectOption(value: 'San Cristóbal', label: 'San Cristóbal'),
    _SelectOption(value: 'Duarte', label: 'Duarte'),
    _SelectOption(value: 'La Altagracia', label: 'La Altagracia'),
    _SelectOption(
      value: 'San Pedro de Macorís',
      label: 'San Pedro de Macorís',
    ),
    _SelectOption(value: 'Espaillat', label: 'Espaillat'),
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
class _StepSelectField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    /// Verificamos si el value actual realmente existe en la lista.
    ///
    /// Esto evita este error típico de Flutter:
    ///
    /// There should be exactly one item with DropdownButton's value.
    final optionExists = options.any((option) => option.value == value);

    /// Si value está vacío o no existe en la lista, usamos null.
    ///
    /// null hace que el Dropdown muestre el placeholder.
    final selectedValue = value.isEmpty || !optionExists ? null : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: selectedValue,
          isExpanded: true,

          /// Fuerza texto oscuro.
          ///
          /// Esto evita que el dropdown herede texto blanco del theme global.
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),

          dropdownColor: AppColors.white,
          iconEnabledColor: AppColors.mutedForeground,

          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryRed,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryRed,
                width: 1.4,
              ),
            ),
          ),

          hint: Text(
            placeholder,
            style: const TextStyle(
              color: Color(0xFF8A94A6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),

          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(
                option.label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ],
    );
  }
}