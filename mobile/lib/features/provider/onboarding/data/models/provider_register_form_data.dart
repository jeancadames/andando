import 'package:file_picker/file_picker.dart';

/// Modelo local para guardar los datos del formulario de registro.
///
/// Importante:
/// Este modelo NO representa una tabla de base de datos.
/// Este modelo solo vive en Flutter mientras el usuario completa los pasos.
///
/// El registro tiene 4 pasos:
///
/// 1. Información personal.
/// 2. Información del negocio.
/// 3. Documentación.
/// 4. Términos y condiciones.
///
/// Al final, este objeto se usa para construir un request multipart
/// hacia Laravel.
class ProviderRegisterFormData {
  /// Paso 1: nombre completo del proveedor.
  String fullName = '';

  /// Paso 1: correo electrónico.
  String email = '';

  /// Paso 1: teléfono de contacto.
  String phone = '';

  /// Paso 1: contraseña.
  String password = '';

  /// Paso 1: confirmación de contraseña.
  String confirmPassword = '';

  /// Paso 2: nombre comercial del negocio.
  String businessName = '';

  /// Paso 2: slug del tipo de negocio.
  ///
  /// Ejemplo:
  /// - tourism_agency
  /// - tour_operator
  /// - tour_guide
  String businessTypeSlug = '';

  /// Paso 2: RNC o identificador tributario.
  String rnc = '';

  /// Paso 2: dirección física del negocio.
  String address = '';

  /// Paso 2: ciudad.
  String city = '';

  /// Paso 2: provincia.
  String province = '';

  /// Paso 3: archivo de cédula.
  ///
  /// Usamos PlatformFile porque viene del paquete file_picker.
  /// Este objeto contiene nombre, tamaño, extensión y bytes del archivo.
  PlatformFile? identityCard;

  /// Paso 3: archivo de certificado RNC.
  PlatformFile? rncCertificate;

  /// Paso 3: licencia comercial opcional.
  PlatformFile? businessLicense;

  /// Paso 4: aceptación de términos.
  bool acceptTerms = false;

  /// Paso 4: aceptación de política de privacidad.
  bool acceptPrivacy = false;
}