import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../../core/config/environment.dart';
import '../models/provider_auth_response.dart';
import '../models/provider_register_form_data.dart';

/// Servicio encargado de comunicarse con Laravel para el flujo de afiliado/proveedor.
///
/// Este archivo es parte de la capa data.
///
/// Responsabilidades:
/// - enviar login de afiliado/proveedor.
/// - enviar registro de afiliado/proveedor.
/// - subir documentos.
/// - consultar el estado actual del afiliado/proveedor.
/// - cerrar sesión en backend.
/// - procesar errores de Laravel.
/// - convertir JSON en modelos Dart.
///
/// Este servicio NO debe tener lógica visual.
/// No muestra SnackBars.
/// No navega entre pantallas.
/// Solo habla con la API.
class ProviderAuthApi {
  const ProviderAuthApi();

  /// Inicia sesión como afiliado/proveedor.
  ///
  /// Endpoint esperado:
  ///
  /// POST /api/provider/login
  ///
  /// Body enviado:
  /// - email
  /// - password
  ///
  /// Laravel debe responder:
  /// - token
  /// - user
  /// - provider
  ///
  /// Ejemplo esperado de respuesta:
  ///
  /// {
  ///   "message": "Inicio de sesión correcto.",
  ///   "token": "1|token...",
  ///   "user": {
  ///     "id": 1,
  ///     "name": "Jean",
  ///     "email": "jeancadames22@gmail.com",
  ///     "phone": "8090000000",
  ///     "type": "provider"
  ///   },
  ///   "provider": {
  ///     "id": 1,
  ///     "business_name": "Tours Jean",
  ///     "status": "approved",
  ///     "rejection_reason": null
  ///   }
  /// }
  ///
  /// Este método devuelve ProviderAuthResponse para que la pantalla
  /// pueda guardar la sesión localmente y redirigir según provider.status.
  Future<ProviderAuthResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/login');

    final response = await http.post(
      uri,
      headers: {
        /// Le decimos a Laravel que queremos respuesta JSON.
        ///
        /// Esto es importante porque Laravel puede responder HTML
        /// si no reconoce que es una petición API.
        'Accept': 'application/json',
      },
      body: {'email': email, 'password': password},
    );

    return _handleAuthResponse(response);
  }

  /// Registra un afiliado/proveedor completo.
  ///
  /// Endpoint esperado:
  ///
  /// POST /api/provider/register
  ///
  /// Se usa MultipartRequest porque el formulario contiene archivos:
  /// - cédula
  /// - certificado RNC
  /// - licencia comercial opcional
  ///
  /// Si Laravel responde correctamente, este método devuelve:
  /// - token
  /// - user
  /// - provider
  ///
  /// Eso permite que Flutter guarde la sesión y mande al usuario
  /// a la pantalla de solicitud pendiente.
  Future<ProviderAuthResponse> register({
    required ProviderRegisterFormData data,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/register');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({'Accept': 'application/json'});

    /// Campos normales del formulario.
    ///
    /// Estos nombres deben coincidir exactamente con los nombres
    /// que Laravel espera en ProviderRegisterRequest.
    request.fields.addAll({
      'full_name': data.fullName,
      'email': data.email,
      'phone': data.phone,
      'password': data.password,
      'password_confirmation': data.confirmPassword,
      'business_name': data.businessName,
      'business_type_slug': data.businessTypeSlug,
      'rnc': data.rnc,
      'address': data.address,
      'city': data.city,
      'province': data.province,
      'accept_terms': data.acceptTerms ? '1' : '0',
      'accept_privacy': data.acceptPrivacy ? '1' : '0',
    });

    /// Archivo obligatorio: cédula.
    ///
    /// El nombre identity_card debe coincidir con Laravel.
    request.files.add(
      _fileToMultipart(fieldName: 'identity_card', file: data.identityCard!),
    );

    /// Archivo obligatorio: certificado RNC.
    ///
    /// El nombre rnc_certificate debe coincidir con Laravel.
    request.files.add(
      _fileToMultipart(
        fieldName: 'rnc_certificate',
        file: data.rncCertificate!,
      ),
    );

    /// Archivo opcional: licencia comercial.
    ///
    /// Solo lo enviamos si el usuario seleccionó un archivo.
    if (data.businessLicense != null) {
      request.files.add(
        _fileToMultipart(
          fieldName: 'business_license',
          file: data.businessLicense!,
        ),
      );
    }

    if (data.insurancePolicy != null) {
      request.files.add(
        _fileToMultipart(
          fieldName: 'insurance_policy',
          file: data.insurancePolicy!,
        ),
      );
    }

    /// Enviamos el request multipart.
    final streamedResponse = await request.send();

    /// Convertimos StreamedResponse a Response normal
    /// para poder leer statusCode y body fácilmente.
    final response = await http.Response.fromStream(streamedResponse);

    return _handleAuthResponse(response);
  }

  /// Consulta el estado actual del afiliado/proveedor autenticado.
  ///
  /// Endpoint esperado:
  ///
  /// GET /api/provider/me
  ///
  /// Este método resuelve este problema:
  ///
  /// - Flutter tiene guardado localmente providerStatus = pending.
  /// - Pero en la base de datos ya cambiaste providers.status = approved.
  /// - El router sigue usando el estado local y deja al usuario en pending.
  ///
  /// Entonces esta función consulta Laravel, obtiene el estado real,
  /// y luego la pantalla puede actualizar AuthController.
  ///
  /// Retorna:
  /// - pending
  /// - approved
  /// - rejected
  /// - suspended
  Future<String> getCurrentProviderStatus({required String token}) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/me');

    final response = await http.get(
      uri,
      headers: {
        /// Le decimos a Laravel que queremos JSON.
        'Accept': 'application/json',

        /// Token de Laravel Sanctum.
        ///
        /// Laravel usa este header para identificar al usuario autenticado.
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(response);

    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessful) {
      throw Exception(
        body['message']?.toString() ?? 'No se pudo consultar el estado.',
      );
    }

    /// Laravel debe responder con una propiedad provider.
    ///
    /// Ejemplo:
    ///
    /// {
    ///   "user": {...},
    ///   "provider": {
    ///     "id": 1,
    ///     "business_name": "Tours Jean",
    ///     "status": "approved"
    ///   }
    /// }
    final provider = body['provider'];

    if (provider == null || provider is! Map<String, dynamic>) {
      throw Exception('Este usuario no tiene perfil de afiliado.');
    }

    final status = provider['status'];

    if (status == null || status.toString().trim().isEmpty) {
      throw Exception('El backend no devolvió el estado del afiliado.');
    }

    return status.toString();
  }

  /// Cierra sesión en Laravel eliminando el token actual.
  ///
  /// Endpoint esperado:
  ///
  /// POST /api/provider/logout
  ///
  /// Este método borra el token en backend.
  ///
  /// Importante:
  /// Aunque este logout remoto falle, la app puede cerrar sesión localmente
  /// usando AuthController.logout().
  ///
  /// Por eso, normalmente la pantalla que llame este método debería hacer:
  ///
  /// try {
  ///   await api.logout(token: token);
  /// } catch (_) {
  ///   // Ignorar error remoto.
  /// }
  ///
  /// await authController.logout();
  Future<void> logout({required String token}) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/logout');

    final response = await http.post(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;

    /// Si el backend responde error, lanzamos excepción.
    ///
    /// La pantalla puede decidir ignorarla si solo quiere cerrar sesión local.
    if (!isSuccessful) {
      final body = _decodeJson(response);

      throw Exception(
        body['message']?.toString() ??
            'No se pudo cerrar sesión en el servidor.',
      );
    }
  }

  /// Convierte un archivo seleccionado con file_picker
  /// en un MultipartFile para enviarlo a Laravel.
  ///
  /// Usamos fromBytes porque funciona tanto en:
  /// - Flutter Web
  /// - Android
  /// - iOS
  ///
  /// Para eso es importante que al seleccionar el archivo usemos:
  ///
  /// FilePicker.pickFiles(withData: true)
  ///
  /// Si withData viene false, file.bytes puede ser null.
  http.MultipartFile _fileToMultipart({
    required String fieldName,
    required PlatformFile file,
  }) {
    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception(
        'No se pudo leer el archivo ${file.name}. Intenta seleccionarlo nuevamente.',
      );
    }

    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: file.name,
      contentType: _guessContentType(file.name),
    );
  }

  /// Detecta el tipo MIME básico según la extensión del archivo.
  ///
  /// Laravel también valida el MIME real del archivo,
  /// pero enviarlo correctamente ayuda a que el backend procese mejor
  /// el multipart.
  MediaType _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.pdf')) {
      return MediaType('application', 'pdf');
    }

    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }

    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }

    /// Fallback razonable.
    ///
    /// En condiciones normales no debería llegar aquí porque
    /// file_picker limita las extensiones permitidas o porque
    /// nosotros validamos las extensiones antes de enviar.
    return MediaType('application', 'octet-stream');
  }

  /// Procesa respuestas de login y registro.
  ///
  /// Si la respuesta es exitosa:
  /// - convierte el JSON a ProviderAuthResponse.
  ///
  /// Si Laravel responde error de validación:
  /// - toma el primer mensaje del array errors.
  ///
  /// Si Laravel responde otro error:
  /// - usa message.
  ///
  /// Si no hay message:
  /// - lanza un error genérico.
  ProviderAuthResponse _handleAuthResponse(http.Response response) {
    final body = _decodeJson(response);

    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccessful) {
      return ProviderAuthResponse.fromJson(body);
    }

    if (body.containsKey('errors')) {
      final errors = body['errors'];

      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
      }
    }

    throw Exception(
      body['message']?.toString() ?? 'Ocurrió un error inesperado.',
    );
  }

  /// Decodifica una respuesta JSON de Laravel.
  ///
  /// Lo separamos en un método reusable porque ahora lo usamos en:
  /// - login/register mediante _handleAuthResponse.
  /// - getCurrentProviderStatus.
  /// - logout.
  ///
  /// Si Laravel responde HTML, texto plano o una pantalla de error,
  /// jsonDecode fallaría. En ese caso lanzamos una excepción más clara.
  Map<String, dynamic> _decodeJson(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      final preview = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;

      throw Exception(
        'El servidor respondió con un formato inválido. '
        'Status: ${response.statusCode}. '
        'Body: $preview',
      );
    }
  }
}
