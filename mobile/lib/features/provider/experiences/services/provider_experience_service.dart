import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/provider_experience.dart';
import '../models/provider_experience_schedule.dart';

import 'package:flutter/foundation.dart';

import '../models/provider_schedule_bookings_response.dart';

class ProviderPricingSettings {
  final double commissionRate;
  final double commissionPercentage;
  final String currency;

  const ProviderPricingSettings({
    required this.commissionRate,
    required this.commissionPercentage,
    required this.currency,
  });

  factory ProviderPricingSettings.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final commissionRate = _readDouble(data['commission_rate'], 0.15);

    return ProviderPricingSettings(
      commissionRate: commissionRate.clamp(0, 1).toDouble(),
      commissionPercentage: _readDouble(
        data['commission_percentage'],
        commissionRate * 100,
      ),
      currency: data['currency']?.toString() ?? 'DOP',
    );
  }

  static double _readDouble(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

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
  List<ProviderExperienceMapPickupPointForm> mapPickupPoints = [];
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
    form.mapPickupPoints = experience.mapPickupPoints
    .map(
      (point) => ProviderExperienceMapPickupPointForm(
        name: point.name,
        address: point.address,
        latitude: point.latitude.toString(),
        longitude: point.longitude.toString(),
        instructions: point.instructions,
      ),
    )
    .toList();

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

class ProviderPlaceSearchResult {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? type;
  final String? category;

  const ProviderPlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.category,
  });

  factory ProviderPlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return ProviderPlaceSearchResult(
      placeId: json['place_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      type: json['type']?.toString(),
      category: json['category']?.toString(),
    );
  }

  bool get hasValidCoordinates {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }
}

class ProviderExperienceMapPickupPointForm {
  String name;
  String address;
  String latitude;
  String longitude;
  String instructions;

  ProviderExperienceMapPickupPointForm({
    this.name = '',
    this.address = '',
    this.latitude = '',
    this.longitude = '',
    this.instructions = '',
  });

  bool get hasValidCoordinates {
    final lat = double.tryParse(latitude.trim());
    final lng = double.tryParse(longitude.trim());

    if (lat == null || lng == null) return false;

    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }
}

class ProviderExperienceService {
  /// Para Chrome local:
  /// http://127.0.0.1:8000/api
  ///
  /// Para emulador Android:
  /// http://10.0.2.2:8000/api
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  bool _isSuccessStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  String _cleanToken(String? token) {
    return token?.trim() ?? '';
  }

  Future<ProviderPricingSettings> getPricingSettings({
    required String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      Uri.parse('$baseUrl/provider/pricing-settings'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (!_isSuccessStatus(response.statusCode)) {
      throw Exception(
        body['message'] ?? 'No se pudo cargar la configuración de precios.',
      );
    }

    return ProviderPricingSettings.fromJson(body);
  }

  Future<List<ProviderPlaceSearchResult>> searchPlaces({
    required String? token,
    required String query,
  }) async {
    _ensureAuthenticated(token);

    final cleanQuery = query.trim();

    if (cleanQuery.length < 3) {
      return [];
    }

    final uri = Uri.parse('$baseUrl/provider/places/search').replace(
      queryParameters: {
        'q': cleanQuery,
        'limit': '5',
      },
    );

    final response = await http.get(
      uri,
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (!_isSuccessStatus(response.statusCode)) {
      throw Exception(
        body['message'] ?? 'No se pudieron buscar ubicaciones.',
      );
    }

    final data = body['data'] as List? ?? [];

    return data
        .whereType<Map>()
        .map(
          (item) => ProviderPlaceSearchResult.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((place) => place.hasValidCoordinates)
        .toList();
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
    _addMapPickupPoints(request, form.mapPickupPoints);
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

  Future<ProviderScheduleBookingsResponse> getScheduleBookings({
    required int experienceId,
    required int scheduleId,
    required String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/provider/experiences/$experienceId/schedules/$scheduleId/bookings',
      ),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar las reservas.',
      );
    }

    return ProviderScheduleBookingsResponse.fromJson(body);
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

    if (!_isSuccessStatus(response.statusCode)) {
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

  void _addMapPickupPoints(
    http.MultipartRequest request,
    List<ProviderExperienceMapPickupPointForm> points,
  ) {
    final validPoints = points
        .where((point) => point.hasValidCoordinates)
        .toList();

    for (int i = 0; i < validPoints.length; i++) {
      final point = validPoints[i];

      request.fields['map_pickup_points[$i][name]'] = point.name.trim();
      request.fields['map_pickup_points[$i][address]'] = point.address.trim();
      request.fields['map_pickup_points[$i][latitude]'] =
          point.latitude.trim();
      request.fields['map_pickup_points[$i][longitude]'] =
          point.longitude.trim();
      request.fields['map_pickup_points[$i][instructions]'] =
          point.instructions.trim();
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

    if (!_isSuccessStatus(response.statusCode)) {
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

    if (!_isSuccessStatus(response.statusCode)) {
      throw Exception(
        body['message'] ?? 'No se pudieron crear las fechas.',
      );
    }
  }
}