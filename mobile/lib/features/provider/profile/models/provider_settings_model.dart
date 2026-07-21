class ProviderSettingsDocument {
  const ProviderSettingsDocument({
    required this.id,
    required this.type,
    required this.label,
    required this.isRequired,
    required this.isUploaded,
    required this.canUpload,
    required this.status,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.viewUrl,
    required this.downloadUrl,
  });

  final int? id;
  final String type;
  final String label;
  final bool isRequired;
  final bool isUploaded;
  final bool canUpload;
  final String? status;
  final String? originalName;
  final String? mimeType;
  final int sizeBytes;
  final String? uploadedAt;
  final String? viewUrl;
  final String? downloadUrl;

  factory ProviderSettingsDocument.fromJson(Map<String, dynamic> json) {
    return ProviderSettingsDocument(
      id: _nullableInt(json['id']),
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      isRequired: _boolValue(json['is_required']),
      isUploaded: _boolValue(json['is_uploaded']),
      canUpload: _boolValue(json['can_upload']),
      status: json['status']?.toString(),
      originalName: json['original_name']?.toString(),
      mimeType: json['mime_type']?.toString(),
      sizeBytes: _intValue(json['size_bytes']),
      uploadedAt: json['uploaded_at']?.toString(),
      viewUrl: json['view_url']?.toString(),
      downloadUrl: json['download_url']?.toString(),
    );
  }
}

class ProviderSettingsModel {
  const ProviderSettingsModel({
    required this.phone,
    required this.city,
    required this.province,
    required this.documents,
  });

  final String phone;
  final String city;
  final String province;
  final List<ProviderSettingsDocument> documents;

  factory ProviderSettingsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final rawDocuments = data['documents'] is List
        ? data['documents'] as List
        : const [];

    return ProviderSettingsModel(
      phone: data['phone']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      province: data['province']?.toString() ?? '',
      documents: rawDocuments
          .whereType<Map>()
          .map(
            (item) => ProviderSettingsDocument.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

bool _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;

  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _intValue(value);
  return parsed <= 0 ? null : parsed;
}
