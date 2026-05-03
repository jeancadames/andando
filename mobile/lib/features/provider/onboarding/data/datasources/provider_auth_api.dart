import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../../core/config/environment.dart';
import '../models/provider_auth_response.dart';
import '../models/provider_register_form_data.dart';

/// Servicio encargado de comunicarse con Laravel para el flujo de proveedor.
///
/// Este archivo es parte de la capa data.
///
/// Responsabilidades:
/// - enviar login de proveedor.
/// - enviar registro de proveedor.
/// - subir documentos.
/// - procesar errores de Laravel.
/// - convertir JSON en modelos Dart.
///
/// Este servicio NO debe tener lógica visual.
/// No muestra SnackBars.
/// No navega entre pantallas.
/// Solo habla con la API.
class ProviderAuthApi {
  const ProviderAuthApi();

  /// Inicia sesión como proveedor.
  ///
  /// Endpoint esperado:
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
      body: {
        'email': email,
        'password': password,
      },
    );

    return _handleAuthResponse(response);
  }

  /// Registra un proveedor completo.
  ///
  /// Endpoint esperado:
  /// POST /api/provider/register
  ///
  /// Se usa MultipartRequest porque el formulario contiene archivos:
  /// - cédula
  /// - certificado RNC
  /// - licencia comercial opcional
  Future<ProviderAuthResponse> register({
    required ProviderRegisterFormData data,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/register');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
    });

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
    request.files.add(
      _fileToMultipart(
        fieldName: 'identity_card',
        file: data.identityCard!,
      ),
    );

    /// Archivo obligatorio: certificado RNC.
    request.files.add(
      _fileToMultipart(
        fieldName: 'rnc_certificate',
        file: data.rncCertificate!,
      ),
    );

    /// Archivo opcional: licencia comercial.
    if (data.businessLicense != null) {
      request.files.add(
        _fileToMultipart(
          fieldName: 'business_license',
          file: data.businessLicense!,
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

  /// Convierte un archivo seleccionado con file_picker
  /// en un MultipartFile para enviarlo a Laravel.
  ///
  /// Usamos fromBytes porque funciona tanto en:
  /// - Flutter Web
  /// - Android
  /// - iOS
  ///
  /// Para eso es importante que al seleccionar el archivo usemos:
  /// withData: true
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
    /// file_picker limita las extensiones permitidas.
    return MediaType('application', 'octet-stream');
  }

  /// Procesa la respuesta de Laravel.
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
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('El servidor respondió con un formato inválido.');
    }

    final isSuccessful = response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccessful) {
      return ProviderAuthResponse.fromJson(body);
    }

    if (body.containsKey('errors')) {
      final errors = body['errors'] as Map<String, dynamic>;

      if (errors.isNotEmpty) {
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
}