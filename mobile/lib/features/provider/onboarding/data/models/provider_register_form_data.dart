import 'package:file_picker/file_picker.dart';

/// Mantiene localmente la información del formulario de registro
/// mientras el afiliado completa sus cuatro pasos.
class ProviderRegisterFormData {
  /*
   * Paso 1: información personal.
   */
  String fullName = '';
  String email = '';
  String phone = '';
  String password = '';
  String confirmPassword = '';

  /*
   * Paso 2: información comercial.
   */
  String businessName = '';
  String businessTypeSlug = '';
  String rnc = '';
  String address = '';
  String city = '';
  String province = '';

  /*
   * Paso 3: documentos de verificación.
   */
  PlatformFile? identityCard;
  PlatformFile? rncCertificate;
  PlatformFile? businessLicense;

  /*
   * Paso 4: confirmaciones legales.
   */
  bool acceptTerms = false;
  bool acceptStandards = false;
  bool acceptPrivacy = false;

  /*
   * Documento vigente de Términos para Afiliados.
   */
  int? termsDocumentId;
  String? termsDocumentChecksum;

  /*
   * Documento vigente de Estándares de Publicación,
   * Operación y Seguridad.
   */
  int? standardsDocumentId;
  String? standardsDocumentChecksum;

  /*
   * Documento vigente de Política de Privacidad.
   */
  int? privacyDocumentId;
  String? privacyDocumentChecksum;

  bool get hasLegalDocuments {
    return termsDocumentId != null &&
        (termsDocumentChecksum?.isNotEmpty ?? false) &&
        standardsDocumentId != null &&
        (standardsDocumentChecksum?.isNotEmpty ?? false) &&
        privacyDocumentId != null &&
        (privacyDocumentChecksum?.isNotEmpty ?? false);
  }

  bool get hasAcceptedLegalDocuments {
    return acceptTerms && acceptStandards && acceptPrivacy;
  }
}
