// lib/features/customer/chat/data/services/customer_chat_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../chat/data/models/chat_conversation_model.dart';
import '../../../../chat/data/models/chat_message_model.dart';

class CustomerChatService {
  String get _baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    final cleanedEnvUrl = _cleanBaseUrl(envUrl);

    if (kIsWeb) {
      if (cleanedEnvUrl.isEmpty || cleanedEnvUrl.contains('10.0.2.2')) {
        return 'http://127.0.0.1:8000/api';
      }

      return cleanedEnvUrl;
    }

    if (cleanedEnvUrl.isNotEmpty) {
      return cleanedEnvUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }

  Future<List<ChatConversationModel>> getConversations({
    required String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      _uri('/client/conversations'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudieron cargar tus conversaciones.',
      );
    }

    final data = body['data'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => ChatConversationModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<ChatConversationModel> createOrGetConversation({
    required String? token,
    required int providerExperienceId,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.post(
      _uri('/client/conversations'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'provider_experience_id': providerExperienceId,
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudo abrir la conversación.',
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw CustomerChatException('La conversación recibida no es válida.');
    }

    return ChatConversationModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<ChatConversationModel> getConversation({
    required String? token,
    required int conversationId,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      _uri('/client/conversations/$conversationId'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudo cargar la conversación.',
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw CustomerChatException('La conversación recibida no es válida.');
    }

    return ChatConversationModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<List<ChatMessageModel>> getMessages({
    required String? token,
    required int conversationId,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      _uri('/client/conversations/$conversationId/messages'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudieron cargar los mensajes.',
      );
    }

    final data = body['data'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => ChatMessageModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<ChatMessageModel> sendMessage({
    required String? token,
    required int conversationId,
    String? message,
    XFile? image,
  }) async {
    _ensureAuthenticated(token);

    final cleanMessage = message?.trim() ?? '';

    if (cleanMessage.isEmpty && image == null) {
      throw CustomerChatException('Escribe un mensaje o selecciona una imagen.');
    }

    if (image != null) {
      return _sendMultipartMessage(
        token: token,
        conversationId: conversationId,
        message: cleanMessage,
        image: image,
      );
    }

    final response = await http.post(
      _uri('/client/conversations/$conversationId/messages'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'message': cleanMessage,
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 201) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudo enviar el mensaje.',
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw CustomerChatException('El mensaje recibido no es válido.');
    }

    return ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<void> markAsRead({
    required String? token,
    required int conversationId,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.post(
      _uri('/client/conversations/$conversationId/read'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudo marcar la conversación como leída.',
      );
    }
  }

  Future<int> getUnreadCount({
    required String? token,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.get(
      _uri('/client/conversations/unread-count'),
      headers: _jsonHeaders(token),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudo cargar el contador de mensajes.',
      );
    }

    final data = body['data'];

    if (data is Map) {
      return _toInt(data['unread_count']);
    }

    return 0;
  }

  Future<void> registerDeviceToken({
    required String? token,
    required String deviceToken,
    String? platform,
    String? deviceName,
  }) async {
    _ensureAuthenticated(token);

    final response = await http.post(
      _uri('/client/device-tokens'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'token': deviceToken,
        'platform': platform,
        'device_name': deviceName,
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudo registrar el token del dispositivo.',
      );
    }
  }

  Future<ChatMessageModel> _sendMultipartMessage({
    required String? token,
    required int conversationId,
    required String message,
    required XFile image,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/client/conversations/$conversationId/messages'),
    );

    request.headers.addAll(_multipartHeaders(token));

    if (message.trim().isNotEmpty) {
      request.fields['message'] = message.trim();
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        await image.readAsBytes(),
        filename: image.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = _decode(response);

    if (response.statusCode != 201) {
      throw CustomerChatException(
        body['message']?.toString() ??
            'No se pudo enviar la imagen.',
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw CustomerChatException('El mensaje recibido no es válido.');
    }

    return ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Uri _uri(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$cleanPath');
  }

  Map<String, String> _jsonHeaders(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token!.trim()}',
    };
  }

  Map<String, String> _multipartHeaders(String? token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token!.trim()}',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{};
    } catch (_) {
      return {
        'message': response.body.isNotEmpty
            ? response.body
            : 'Respuesta inválida del servidor.',
      };
    }
  }

  void _ensureAuthenticated(String? token) {
    if (token == null || token.trim().isEmpty) {
      throw CustomerChatException('No hay token de autenticación.');
    }
  }

  String _cleanBaseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}

class CustomerChatException implements Exception {
  final String message;

  const CustomerChatException(this.message);

  @override
  String toString() => message;
}