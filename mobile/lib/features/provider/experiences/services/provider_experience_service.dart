import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/map_pickup_point.dart';
import '../models/place_search_result.dart';
import '../models/provider_experience.dart';
import '../models/provider_experience_schedule.dart';
import '../models/provider_schedule_bookings_response.dart';

import '../../../../core/config/api_config.dart';

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
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}

class ProviderExperienceForm {
  String title = '';
  String category = '';
  String description = '';
  String duration = '';
  int capacity = 1;

  double price = 0;
  bool allowsDiscount = false;
  double? discountPercentage;
  String currency = 'DOP';

  double get effectivePrice {
    if (!allowsDiscount || price <= 0) return price;

    final percentage = (discountPercentage ?? 0).clamp(0, 90).toDouble();
    return double.parse((price * (1 - (percentage / 100))).toStringAsFixed(2));
  }

  String province = '';

  String experienceAddress = '';
  String? experiencePlaceId;
  double? experienceLatitude;
  double? experienceLongitude;
  bool includesTransport = false;
  bool allowsMinors = false;
  ExperienceDifficulty? difficultyLevel;

  List<String> pickupPoints = [''];
  List<MapPickupPoint> mapPickupPoints = [];

  List<Map<String, String>> itinerary = [
    {'time': '', 'activity': ''},
  ];

  List<String> amenities = [];
  List<String> included = [''];
  List<String> notIncluded = [''];
  List<String> requirements = [''];

  String cancellationPolicy = '';

  List<ProviderExperiencePhoto> existingPhotos = [];
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
    form.allowsDiscount = experience.allowsDiscount;
    form.discountPercentage = experience.discountPercentage;
    form.currency = experience.currency;
    form.province = experience.province ?? '';

    form.experienceAddress = experience.experienceAddress ?? '';
    form.experiencePlaceId = experience.experiencePlaceId;
    form.experienceLatitude = experience.experienceLatitude;
    form.experienceLongitude = experience.experienceLongitude;
    form.includesTransport = experience.includesTransport;
    form.allowsMinors = experience.allowsMinors;
    form.difficultyLevel = experience.difficultyLevel;

    form.pickupPoints = experience.pickupPoints.isEmpty
        ? ['']
        : experience.pickupPoints;
    form.mapPickupPoints = experience.mapPickupPoints;

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
    form.notIncluded = experience.notIncluded.isEmpty
        ? ['']
        : experience.notIncluded;
    form.requirements = experience.requirements.isEmpty
        ? ['']
        : experience.requirements;
    form.cancellationPolicy = experience.cancellationPolicy ?? '';
    form.existingPhotos = List<ProviderExperiencePhoto>.from(experience.photos);

    return form;
  }
}

class ProviderScheduleCancellationResult {
  final String message;
  final String? scheduleStatus;
  final bool requiresSupportTicket;
  final bool supportTicketPlaceholder;

  const ProviderScheduleCancellationResult({
    required this.message,
    required this.scheduleStatus,
    required this.requiresSupportTicket,
    required this.supportTicketPlaceholder,
  });

  factory ProviderScheduleCancellationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProviderScheduleCancellationResult(
      message: json['message']?.toString() ?? 'Solicitud procesada.',
      scheduleStatus: json['schedule_status']?.toString(),
      requiresSupportTicket: _readBool(json['requires_support_ticket']),
      supportTicketPlaceholder: _readBool(json['support_ticket_placeholder']),
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }
}

class ProviderExperienceService {
  /// Para Chrome local:
  /// http://127.0.0.1:8000/api
  ///
  /// Para emulador Android:
  /// http://10.0.2.2:8000/api
  static String get baseUrl => ApiConfig.baseUrl;

  bool _isSuccessStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  String _cleanToken(String? token) {
    return token?.trim() ?? '';
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

  Map<String, String> _formHeaders(String? token) {
    final cleanToken = _cleanToken(token);

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
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

  Future<List<PlaceSearchResult>> searchPlaces({
    required String? token,
    required String query,
  }) async {
    _ensureAuthenticated(token);

    final cleanQuery = query.trim();

    if (cleanQuery.length < 3) {
      return [];
    }

    final uri = Uri.parse(
      '$baseUrl/provider/places/search',
    ).replace(queryParameters: {'q': cleanQuery, 'limit': '8'});

    final response = await http.get(uri, headers: _jsonHeaders(token));

    final body = _decode(response);

    if (!_isSuccessStatus(response.statusCode)) {
      throw Exception(body['message'] ?? 'No se pudieron buscar lugares.');
    }

    final data = body['data'] as List? ?? [];

    return data
        .whereType<Map>()
        .map(
          (item) => PlaceSearchResult.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<ProviderExperience>> listExperiences({
    required String? token,
    String? status,
  }) async {
    _ensureAuthenticated(token);

    final uri = Uri.parse(
      '$baseUrl/provider/experiences',
    ).replace(queryParameters: status == null ? null : {'status': status});

    final response = await http.get(uri, headers: _jsonHeaders(token));

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
      throw Exception(body['message'] ?? 'No se pudo cargar la experiencia.');
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
    request.fields['allows_discount'] = form.allowsDiscount ? '1' : '0';

    if (form.allowsDiscount && form.discountPercentage != null) {
      request.fields['discount_percentage'] = form.discountPercentage
          .toString();
    }

    request.fields['currency'] = form.currency;
    request.fields['province'] = form.province;
    request.fields['includes_transport'] = form.includesTransport ? '1' : '0';
    request.fields['allows_minors'] = form.allowsMinors ? '1' : '0';

    if (form.difficultyLevel != null) {
      request.fields['difficulty_level'] = form.difficultyLevel!.apiValue;
    }
    request.fields['cancellation_policy'] = form.cancellationPolicy;

    request.fields['experience_address'] = form.experienceAddress;

    if (form.experiencePlaceId?.trim().isNotEmpty == true) {
      request.fields['experience_place_id'] = form.experiencePlaceId!.trim();
    }

    if (form.experienceLatitude != null) {
      request.fields['experience_latitude'] = form.experienceLatitude
          .toString();
    }

    if (form.experienceLongitude != null) {
      request.fields['experience_longitude'] = form.experienceLongitude
          .toString();
    }

    _addStringArray(request, 'pickup_points', form.pickupPoints);
    _addMapPickupPoints(request, form.mapPickupPoints);

    _addStringArray(request, 'amenities', form.amenities);
    _addStringArray(request, 'included', form.included);
    _addStringArray(request, 'not_included', form.notIncluded);
    _addStringArray(request, 'requirements', form.requirements);

    for (int i = 0; i < form.itinerary.length; i++) {
      request.fields['itinerary[$i][time]'] = form.itinerary[i]['time'] ?? '';

      request.fields['itinerary[$i][activity]'] =
          form.itinerary[i]['activity'] ?? '';
    }

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
      throw Exception(body['message'] ?? 'No se pudo guardar la experiencia.');
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
      throw Exception(body['message'] ?? 'No se pudo eliminar la experiencia.');
    }
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
      Uri.parse(
        '$baseUrl/provider/experiences/$experienceId/schedules/$scheduleId',
      ),
      headers: _jsonHeaders(token),
      body: jsonEncode({'starts_at': '$date $time:00', 'status': 'active'}),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'No se pudo actualizar la fecha.');
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
      throw Exception(body['message'] ?? 'No se pudieron cargar las fechas.');
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
      throw Exception(body['message'] ?? 'No se pudieron cargar las reservas.');
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
      throw Exception(body['message'] ?? 'No se pudo crear la fecha.');
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
      throw Exception(body['message'] ?? 'No se pudo crear la fecha.');
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
      throw Exception(body['message'] ?? 'No se pudieron crear las fechas.');
    }
  }

  Future<ProviderScheduleCancellationResult> cancelSchedule({
    required int experienceId,
    required int scheduleId,
    required String? token,
    required String reasonType,
    required String reasonDescription,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.post(
      Uri.parse(
        '$baseUrl/provider/experiences/$experienceId/schedules/$scheduleId/cancel',
      ),
      headers: _formHeaders(token),
      body: {
        'reason_type': reasonType,
        'reason_description': reasonDescription,
      },
    );

    final body = _decode(response);

    if (response.statusCode == 409 &&
        ProviderScheduleCancellationResult._readBool(
          body['requires_support_ticket'],
        )) {
      return ProviderScheduleCancellationResult.fromJson(body);
    }

    if (!_isSuccessStatus(response.statusCode)) {
      throw Exception(body['message'] ?? 'No se pudo cancelar la fecha.');
    }

    return ProviderScheduleCancellationResult.fromJson(body);
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
      throw Exception(body['message'] ?? 'No se pudo eliminar la fecha.');
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
    List<MapPickupPoint> points,
  ) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      request.fields['map_pickup_points[$i][name]'] = point.name;
      request.fields['map_pickup_points[$i][address]'] = point.address;
      request.fields['map_pickup_points[$i][latitude]'] = point.latitude
          .toString();
      request.fields['map_pickup_points[$i][longitude]'] = point.longitude
          .toString();

      if (point.placeId?.trim().isNotEmpty == true) {
        request.fields['map_pickup_points[$i][place_id]'] = point.placeId!
            .trim();
      }

      if (point.instructions != null && point.instructions!.trim().isNotEmpty) {
        request.fields['map_pickup_points[$i][instructions]'] =
            point.instructions!;
      }
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
}
