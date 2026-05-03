import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Tarjeta reutilizable para subir documentos.
///
/// Se usa en el paso 3 del registro.
/// Cada tarjeta representa un documento:
/// - cédula.
/// - certificado RNC.
/// - licencia comercial.
///
/// Estados visuales:
/// - sin archivo: borde gris punteado.
/// - con archivo: borde verde y nombre del archivo.
class ProviderFileUploadCard extends StatelessWidget {
  const ProviderFileUploadCard({
    super.key,
    required this.label,
    required this.description,
    required this.file,
    required this.onTap,
    this.isRequired = false,
  });

  /// Label visible encima de la tarjeta.
  final String label;

  /// Texto interno de ayuda.
  final String description;

  /// Archivo seleccionado.
  ///
  /// Si es null, todavía no se ha seleccionado archivo.
  final PlatformFile? file;

  /// Acción para abrir el file picker.
  final VoidCallback onTap;

  /// Marca si el documento es obligatorio.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: hasFile
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasFile
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFD1D5DB),
                width: 1.4,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  hasFile ? Icons.check_circle_outline : Icons.upload_outlined,
                  color: hasFile
                      ? const Color(0xFF15803D)
                      : AppColors.mutedForeground,
                  size: 34,
                ),
                const SizedBox(height: 10),
                Text(
                  hasFile ? file!.name : description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasFile
                        ? const Color(0xFF15803D)
                        : AppColors.mutedForeground,
                    fontSize: 14,
                    fontWeight: hasFile ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PDF o imagen (Max 5MB)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}