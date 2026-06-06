// lib/features/chat/data/models/chat_conversation_model.dart

class ChatConversationModel {
  final int id;
  final String status;
  final String? closedReason;
  final DateTime? closedAt;

  final int customerUserId;
  final int providerId;
  final int providerExperienceId;
  final int? providerBookingId;

  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  final int autoClosesAfterHours;
  final String inactivityNotice;

  final ChatExperienceModel? experience;
  final ChatProviderModel? provider;
  final ChatCustomerModel? customer;
  final ChatBookingModel? booking;

  const ChatConversationModel({
    required this.id,
    required this.status,
    required this.closedReason,
    required this.closedAt,
    required this.customerUserId,
    required this.providerId,
    required this.providerExperienceId,
    required this.providerBookingId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.autoClosesAfterHours,
    required this.inactivityNotice,
    required this.experience,
    required this.provider,
    required this.customer,
    required this.booking,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: _toInt(json['id']),
      status: json['status']?.toString() ?? 'open',
      closedReason: json['closed_reason']?.toString(),
      closedAt: _toDate(json['closed_at']),
      customerUserId: _toInt(json['customer_user_id']),
      providerId: _toInt(json['provider_id']),
      providerExperienceId: _toInt(json['provider_experience_id']),
      providerBookingId: json['provider_booking_id'] == null
          ? null
          : _toInt(json['provider_booking_id']),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: _toDate(json['last_message_at']),
      unreadCount: _toInt(json['unread_count']),
      autoClosesAfterHours: _toInt(json['auto_closes_after_hours'], fallback: 72),
      inactivityNotice: json['inactivity_notice']?.toString() ??
          'Este chat se cierra automáticamente después de 72 horas sin interacción.',
      experience: json['experience'] is Map
          ? ChatExperienceModel.fromJson(
              Map<String, dynamic>.from(json['experience']),
            )
          : null,
      provider: json['provider'] is Map
          ? ChatProviderModel.fromJson(
              Map<String, dynamic>.from(json['provider']),
            )
          : null,
      customer: json['customer'] is Map
          ? ChatCustomerModel.fromJson(
              Map<String, dynamic>.from(json['customer']),
            )
          : null,
      booking: json['booking'] is Map
          ? ChatBookingModel.fromJson(
              Map<String, dynamic>.from(json['booking']),
            )
          : null,
    );
  }

  bool get isOpen => status == 'open';

  bool get isClosed => status == 'closed';

  bool get hasUnreadMessages => unreadCount > 0;

  String get experienceTitle {
    return experience?.title?.trim().isNotEmpty == true
        ? experience!.title!
        : 'Experiencia';
  }

  String get providerName {
    final businessName = provider?.businessName?.trim();

    if (businessName != null && businessName.isNotEmpty) {
      return businessName;
    }

    final userName = provider?.userName?.trim();

    if (userName != null && userName.isNotEmpty) {
      return userName;
    }

    return 'Afiliado';
  }

  String get customerName {
    final name = customer?.name?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Cliente';
  }

  String get displayLastMessage {
    final value = lastMessage?.trim();

    if (value == null || value.isEmpty) {
      return 'Sin mensajes todavía';
    }

    return value;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}

class ChatExperienceModel {
  final int id;
  final String? title;
  final String? coverPhotoUrl;

  const ChatExperienceModel({
    required this.id,
    required this.title,
    required this.coverPhotoUrl,
  });

  factory ChatExperienceModel.fromJson(Map<String, dynamic> json) {
    return ChatExperienceModel(
      id: ChatConversationModel._toInt(json['id']),
      title: json['title']?.toString(),
      coverPhotoUrl: json['cover_photo_url']?.toString(),
    );
  }
}

class ChatProviderModel {
  final int id;
  final String? businessName;
  final String? userName;

  const ChatProviderModel({
    required this.id,
    required this.businessName,
    required this.userName,
  });

  factory ChatProviderModel.fromJson(Map<String, dynamic> json) {
    return ChatProviderModel(
      id: ChatConversationModel._toInt(json['id']),
      businessName: json['business_name']?.toString(),
      userName: json['user_name']?.toString(),
    );
  }
}

class ChatCustomerModel {
  final int id;
  final String? name;
  final String? email;

  const ChatCustomerModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ChatCustomerModel.fromJson(Map<String, dynamic> json) {
    return ChatCustomerModel(
      id: ChatConversationModel._toInt(json['id']),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class ChatBookingModel {
  final int id;
  final String bookingCode;
  final String status;

  const ChatBookingModel({
    required this.id,
    required this.bookingCode,
    required this.status,
  });

  factory ChatBookingModel.fromJson(Map<String, dynamic> json) {
    return ChatBookingModel(
      id: ChatConversationModel._toInt(json['id']),
      bookingCode: json['booking_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}