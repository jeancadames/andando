// lib/features/chat/data/models/chat_message_model.dart

class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderUserId;
  final String senderType;
  final String? senderName;

  final String? message;

  final String? attachmentType;
  final String? attachmentUrl;
  final String? attachmentOriginalName;
  final String? attachmentMimeType;
  final int? attachmentSizeBytes;

  final DateTime? readAt;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderType,
    required this.senderName,
    required this.message,
    required this.attachmentType,
    required this.attachmentUrl,
    required this.attachmentOriginalName,
    required this.attachmentMimeType,
    required this.attachmentSizeBytes,
    required this.readAt,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversation_id']),
      senderUserId: _toInt(json['sender_user_id']),
      senderType: json['sender_type']?.toString() ?? '',
      senderName: json['sender_name']?.toString(),
      message: json['message']?.toString(),
      attachmentType: json['attachment_type']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentOriginalName: json['attachment_original_name']?.toString(),
      attachmentMimeType: json['attachment_mime_type']?.toString(),
      attachmentSizeBytes: json['attachment_size_bytes'] == null
          ? null
          : _toInt(json['attachment_size_bytes']),
      readAt: _toDate(json['read_at']),
      createdAt: _toDate(json['created_at']),
    );
  }

  bool get hasText {
    return message != null && message!.trim().isNotEmpty;
  }

  bool get hasAttachment {
    return attachmentUrl != null && attachmentUrl!.trim().isNotEmpty;
  }

  bool get hasImage {
    return attachmentType == 'image' && hasAttachment;
  }

  bool isMine(String currentSenderType) {
    return senderType == currentSenderType;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}