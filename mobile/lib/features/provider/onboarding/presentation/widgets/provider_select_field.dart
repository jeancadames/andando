import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Opción reutilizable para dropdowns.
///
/// Ejemplo:
///
/// ProviderSelectOption(
///   value: 'tourism_agency',
///   label: 'Agencia de Turismo',
/// )
class ProviderSelectOption {
  const ProviderSelectOption({
    required this.value,
    required this.label,
  });

  /// Valor que se enviará al backend.
  final String value;

  /// Texto visible para el usuario.
  final String label;
}

/// Dropdown reutilizable para el flujo de proveedor.
///
/// Lo usamos para:
/// - tipo de negocio.
/// - provincia.
class ProviderSelectField extends StatelessWidget {
  const ProviderSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.items,
    required this.onChanged,
  });

  final String label;

  /// Valor actualmente seleccionado.
  ///
  /// Puede venir vacío si el usuario no ha seleccionado nada.
  final String value;

  /// Texto mostrado cuando no hay selección.
  final String placeholder;

  /// Lista de opciones del dropdown.
  final List<ProviderSelectOption> items;

  /// Callback cuando el usuario selecciona un valor.
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.isEmpty ? null : value;

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
          value: normalizedValue,
          isExpanded: true,
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
          ),
          hint: Text(
            placeholder,
            style: const TextStyle(
              color: Color(0xFF8A94A6),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item.value,
              child: Text(item.label),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}