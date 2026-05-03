import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Paso 3 del registro de proveedor.
///
/// En este paso el proveedor sube los documentos necesarios
/// para que AndanDO pueda validar su cuenta.
///
/// Documentos requeridos:
/// - Cédula de identidad.
/// - Certificado RNC.
///
/// Documento opcional:
/// - Licencia comercial.
///
/// Este widget NO abre directamente el selector de archivos.
/// Solo llama callbacks que vienen desde ProviderRegisterScreen.
///
/// ¿Por qué?
/// Porque el screen padre debe guardar los archivos seleccionados
/// dentro de ProviderRegisterFormData.
class StepDocuments extends StatelessWidget {
  const StepDocuments({
    super.key,
    required this.identityCard,
    required this.rncCertificate,
    required this.businessLicense,
    required this.onPickIdentityCard,
    required this.onPickRncCertificate,
    required this.onPickBusinessLicense,
  });

  /// Archivo de cédula seleccionado.
  final PlatformFile? identityCard;

  /// Archivo de certificado RNC seleccionado.
  final PlatformFile? rncCertificate;

  /// Archivo de licencia comercial seleccionado.
  ///
  /// Este documento es opcional.
  final PlatformFile? businessLicense;

  /// Callback para seleccionar cédula.
  final VoidCallback onPickIdentityCard;

  /// Callback para seleccionar certificado RNC.
  final VoidCallback onPickRncCertificate;

  /// Callback para seleccionar licencia comercial.
  final VoidCallback onPickBusinessLicense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Título del paso.
        const Text(
          'Documentación',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        /// Subtítulo.
        const Text(
          'Sube los documentos requeridos para verificación',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),

        const SizedBox(height: 24),

        /// Caja informativa.
        ///
        /// Explica al proveedor el requisito general de los documentos.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFBFDBFE),
            ),
          ),
          child: const Text(
            '📌 Todos los documentos deben estar vigentes y ser legibles. '
            'El proceso de verificación toma 24-48 horas.',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),

        const SizedBox(height: 24),

        _DocumentUploadCard(
          label: 'Cédula de identidad',
          isRequired: true,
          file: identityCard,
          emptyTitle: 'Toca para subir cédula',
          onTap: onPickIdentityCard,
        ),

        const SizedBox(height: 20),

        _DocumentUploadCard(
          label: 'Certificado RNC',
          isRequired: true,
          file: rncCertificate,
          emptyTitle: 'Toca para subir certificado RNC',
          onTap: onPickRncCertificate,
        ),

        const SizedBox(height: 20),

        _DocumentUploadCard(
          label: 'Licencia comercial',
          isRequired: false,
          file: businessLicense,
          emptyTitle: 'Toca para subir licencia',
          onTap: onPickBusinessLicense,
        ),
      ],
    );
  }
}

/// Tarjeta interna para seleccionar archivos.
///
/// La usamos tres veces:
/// - cédula.
/// - certificado RNC.
/// - licencia comercial.
///
/// Si el archivo ya fue seleccionado:
/// - muestra check.
/// - muestra el nombre del archivo.
/// - cambia estilo a verde.
///
/// Si no hay archivo:
/// - muestra icono de upload.
/// - muestra texto guía.
/// - mantiene estilo gris claro.
class _DocumentUploadCard extends StatelessWidget {
  const _DocumentUploadCard({
    required this.label,
    required this.isRequired,
    required this.file,
    required this.emptyTitle,
    required this.onTap,
  });

  /// Nombre del documento.
  final String label;

  /// Define si el documento es requerido.
  final bool isRequired;

  /// Archivo seleccionado.
  final PlatformFile? file;

  /// Texto cuando no hay archivo.
  final String emptyTitle;

  /// Acción para abrir file picker.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : '$label (Opcional)',
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
              vertical: 26,
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
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  hasFile ? Icons.check_circle_outline : Icons.upload_outlined,
                  size: 34,
                  color: hasFile
                      ? const Color(0xFF15803D)
                      : AppColors.mutedForeground,
                ),

                const SizedBox(height: 10),

                Text(
                  hasFile ? file!.name : emptyTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasFile
                        ? const Color(0xFF15803D)
                        : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: hasFile ? FontWeight.w700 : FontWeight.w500,
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