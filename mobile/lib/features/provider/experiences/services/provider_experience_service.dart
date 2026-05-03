import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/provider_experience.dart';
import '../models/provider_experience_schedule.dart';

import 'package:flutter/foundation.dart';

class ProviderExperienceForm {
  String title = '';
  String category = '';
  String description = '';
  String duration = '';
  int capacity = 1;

  double price = 0;
  String currency = 'DOP';
  String startLocation = '';
  String province = '';

  List<String> pickupPoints = [''];
  List<Map<String, String>> itinerary = [
    {'time': '', 'activity': ''},
  ];

  List<String> amenities = [];
  List<String> included = [''];
  List<String> notIncluded = [''];
  List<String> requirements = [''];

  String cancellationPolicy = '';

  /// Fotos nuevas seleccionadas por el afiliado.
  ///
  /// XFile funciona correctamente en Flutter Web y mobile.
  List<XFile> photos = [];

  ProviderExperienceForm();

  factory ProviderExperienceForm.fromExperience(ProviderExperience experience) {
    final form = ProviderExperienceForm();

    form.title = experience.title;
    form.category = experience.category ?? '';
    form.description = experience.description ?? '';
    form.duration = experience.duration ?? '';
    form.capacity = experience.capacity;
    form.price = experience.price;
    form.currency = experience.currency;
    form.startLocation = experience.startLocation ?? '';
    form.province = experience.province ?? '';
    form.pickupPoints =
        experience.pickupPoints.isEmpty ? [''] : experience.pickupPoints;

    form.itinerary = experience.itinerary.isEmpty
        ? [
            {'time': '', 'activity': ''},
          ]
        : experience.itinerary
            .map(
              (item) => {
                'time': item['time']?.toString() ?? '',
                'activity': item['activity']?.toString() ?? '',
              },
            )
            .toList();

    form.amenities = experience.amenities;
    form.included = experience.included.isEmpty ? [''] : experience.included;
    form.notIncluded =
        experience.notIncluded.isEmpty ? [''] : experience.notIncluded;
    form.requirements =
        experience.requirements.isEmpty ? [''] : experience.requirements;
    form.cancellationPolicy = experience.cancellationPolicy ?? '';

    return form;
  }
}

class ProviderExperienceService {
  /// Para Chrome local:
  /// http://127.0.0.1:8000/api
  ///
  /// Para emulador Android:
  /// http://10.0.2.2:8000/api
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  String _cleanToken(String? token) {
    return token?.trim() ?? '';
  }

  Future<void> updateSchedule({
    required int experienceId,
    required int scheduleId,
    required String? token,
    required String date,
    required String time,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.put(
      Uri.parse('$baseUrl/provider/experiences/$experienceId/schedules/$scheduleId'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        // El backend actual acepta starts_at.
        // Enviamos formato local simple para evitar problemas de UTC/Z.
        'starts_at': '$date $time:00',
        'status': 'active',
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo actualizar la fecha.',
      );
    }
  }

  void _ensureAuthenticated(String? token) {
    if (_cleanToken(token).isEmpty) {
      throw Exception(
        'Tu sesión expiró o no se encontró el token de autenticación.',
      );
    }
  }

  Map<String, String> _jsonHeaders(String? token) {
    final cleanToken = _cleanToken(token);

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (cleanToken.isNotEmpty) 'Authorization': 'Bearer $cleanToken',
    };
  }

  Map<String, String> _multipartHeaders(String? token) {
    final cleanToken = _cleanToken(token);

    return {
      'Accept': 'application/json',
      if (cleanToken.isNotEmpty) 'Authorization': 'Bearer $cleanToken',
    };
  }

  Future<List<ProviderExperience>> listExperiences({
    required String? token,
    String? status,
  }) async {
    _ensureAuthenticated(token);

    final uri = Uri.parse('$baseUrl/provider/experiences').replace(
      queryParameters: status == null ? null : {'status': status},
    );

    final response = await http.get(
      uri,
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar las experiencias.',
      );
    }

    final data = body['data'] as List? ?? [];

    return data.map((item) => ProviderExperience.fromJson(item)).toList();
  }

  Future<ProviderExperience> getExperience({
    required int id,
    required String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      Uri.parse('$baseUrl/provider/experiences/$id'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo cargar la experiencia.',
      );
    }

    return ProviderExperience.fromJson(body['data']);
  }

  Future<ProviderExperience> saveExperience({
    required ProviderExperienceForm form,
    required String? token,
    int? experienceId,
    required bool publish,
  }) async {
    _ensureAuthenticated(token);

    final uri = experienceId == null
        ? Uri.parse('$baseUrl/provider/experiences')
        : Uri.parse('$baseUrl/provider/experiences/$experienceId');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_multipartHeaders(token));

    request.fields['publish'] = publish ? '1' : '0';

    request.fields['title'] = form.title;
    request.fields['category'] = form.category;
    request.fields['description'] = form.description;
    request.fields['duration'] = form.duration;
    request.fields['capacity'] = form.capacity.toString();
    request.fields['price'] = form.price.toString();
    request.fields['currency'] = form.currency;
    request.fields['start_location'] = form.startLocation;
    request.fields['province'] = form.province;
    request.fields['cancellation_policy'] = form.cancellationPolicy;

    _addStringArray(request, 'pickup_points', form.pickupPoints);
    _addStringArray(request, 'amenities', form.amenities);
    _addStringArray(request, 'included', form.included);
    _addStringArray(request, 'not_included', form.notIncluded);
    _addStringArray(request, 'requirements', form.requirements);

    for (int i = 0; i < form.itinerary.length; i++) {
      request.fields['itinerary[$i][time]'] =
          form.itinerary[i]['time'] ?? '';

      request.fields['itinerary[$i][activity]'] =
          form.itinerary[i]['activity'] ?? '';
    }

    /// En Flutter Web no se puede usar MultipartFile.fromPath.
    /// Usamos bytes para que funcione en Chrome, Android e iOS.
    for (int i = 0; i < form.photos.length; i++) {
      final photo = form.photos[i];

      request.files.add(
        http.MultipartFile.fromBytes(
          'photos[$i]',
          await photo.readAsBytes(),
          filename: photo.name,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudo guardar la experiencia.',
      );
    }

    return ProviderExperience.fromJson(body['data']);
  }

  Future<void> deleteExperience({
    required int id,
    required String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.delete(
      Uri.parse('$baseUrl/provider/experiences/$id'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo eliminar la experiencia.',
      );
    }
  }

  Future<List<ProviderExperienceSchedule>> listSchedules(
    int experienceId, {
    String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      Uri.parse('$baseUrl/provider/experiences/$experienceId/schedules'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);
    debugPrint('SCHEDULES STATUS: ${response.statusCode}');
    debugPrint('SCHEDULES BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar las fechas.',
      );
    }

    final data = body['data'] as List? ?? [];

    return data
        .map((item) => ProviderExperienceSchedule.fromJson(item))
        .toList();
  }

  Future<void> createSchedule({
    required int experienceId,
    required String? token,
    required DateTime startsAt,
    required int capacity,
    required double price,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.post(
      Uri.parse('$baseUrl/provider/experiences/$experienceId/schedules'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'starts_at': startsAt.toIso8601String(),
        'capacity': capacity,
        'price': price,
        'currency': 'DOP',
        'timezone': 'America/Santo_Domingo',
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudo crear la fecha.',
      );
    }
  }

  Future<void> deleteSchedule({
    required int experienceId,
    required int scheduleId,
    required String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.delete(
      Uri.parse(
        '$baseUrl/provider/experiences/$experienceId/schedules/$scheduleId',
      ),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo eliminar la fecha.',
      );
    }
  }

  void _addStringArray(
    http.MultipartRequest request,
    String key,
    List<String> values,
  ) {
    for (int i = 0; i < values.length; i++) {
      request.fields['$key[$i]'] = values[i];
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'message': response.body.isNotEmpty
            ? response.body
            : 'Respuesta inválida del servidor.',
      };
    }
  }

  Future<void> createSingleSchedule({
    required int experienceId,
    required String? token,
    required String date,
    required String time,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.post(
      Uri.parse('$baseUrl/provider/experiences/$experienceId/schedules'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'schedule_type': 'single',
        'date': date,
        'time': time,
        'timezone': 'America/Santo_Domingo',
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudo crear la fecha.',
      );
    }
  }

  Future<void> createMultipleSchedules({
    required int experienceId,
    required String? token,
    required String startDate,
    required String endDate,
    required String time,
    required String frequency,
    required List<String> daysOfWeek,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.post(
      Uri.parse('$baseUrl/provider/experiences/$experienceId/schedules'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'schedule_type': 'multiple',
        'start_date': startDate,
        'end_date': endDate,
        'time': time,
        'frequency': frequency,
        'days_of_week': daysOfWeek,
        'timezone': 'America/Santo_Domingo',
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudieron crear las fechas.',
      );
    }
  }
}