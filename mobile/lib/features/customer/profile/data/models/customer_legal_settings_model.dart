class CustomerLegalDocumentModel {
  final int id;
  final String type;
  final String title;
  final String? summary;
  final String version;
  final String? effectiveAt;
  final bool requiresAcceptance;
  final bool accepted;
  final String? acceptedAt;
  final String? acceptedLabel;
  final String acceptanceScope;

  const CustomerLegalDocumentModel({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.version,
    required this.effectiveAt,
    required this.requiresAcceptance,
    required this.accepted,
    required this.acceptedAt,
    required this.acceptedLabel,
    required this.acceptanceScope,
  });

  factory CustomerLegalDocumentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawVersion = json['version']?.toString().trim() ?? '';

    return CustomerLegalDocumentModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Documento legal',
      summary: json['summary']?.toString(),
      version: rawVersion.isEmpty
          ? 'v1.0'
          : rawVersion.startsWith('v')
              ? rawVersion
              : 'v$rawVersion',
      effectiveAt: json['effective_at']?.toString(),
      requiresAcceptance: json['requires_acceptance'] == true,
      accepted: json['accepted'] == true,
      acceptedAt: json['accepted_at']?.toString(),
      acceptedLabel: json['accepted_label']?.toString(),
      acceptanceScope:
        json['acceptance_scope']?.toString() ?? 'informational',
    );
  }
}

class CustomerLegalSettingsModel {
  final String? termsAcceptedAt;
  final String? termsAcceptedLabel;
  final bool termsAccepted;
  final List<CustomerLegalDocumentModel> documents;
  final String termsVersion;
  final String privacyVersion;
  final String cookiesVersion;
  final String rnc;
  final String supportEmail;

  const CustomerLegalSettingsModel({
    required this.termsAcceptedAt,
    required this.termsAcceptedLabel,
    required this.termsAccepted,
    required this.documents,
    required this.termsVersion,
    required this.privacyVersion,
    required this.cookiesVersion,
    required this.rnc,
    required this.supportEmail,
  });

  factory CustomerLegalSettingsModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] ?? {});

    final terms = Map<String, dynamic>.from(data['terms'] ?? {});
    final privacy = Map<String, dynamic>.from(data['privacy'] ?? {});
    final cookies = Map<String, dynamic>.from(data['cookies'] ?? {});
    final contact = Map<String, dynamic>.from(data['contact'] ?? {});
    final corporateNotice = Map<String, dynamic>.from(
      data['corporate_notice'] ?? {},
    );
    final rawDocuments = data['documents'];

    final documents = rawDocuments is List
        ? rawDocuments
            .whereType<Map>()
            .map(
              (document) => CustomerLegalDocumentModel.fromJson(
                Map<String, dynamic>.from(document),
              ),
            )
            .toList()
        : <CustomerLegalDocumentModel>[];

    String formatVersion(dynamic value) {
      final version = value?.toString().trim() ?? '';

      if (version.isEmpty) {
        return 'v1.0';
      }

      return version.startsWith('v') ? version : 'v$version';
    }

    return CustomerLegalSettingsModel(
      termsAcceptedAt: terms['accepted_at']?.toString(),
      termsAcceptedLabel: terms['accepted_label']?.toString(),
      termsAccepted: terms['accepted'] == true,
      termsVersion: formatVersion(terms['version']),
      privacyVersion: formatVersion(privacy['version']),
      cookiesVersion: formatVersion(cookies['version']),
      rnc: corporateNotice['rnc']?.toString() ?? '',
      supportEmail:
          contact['support_email']?.toString() ?? 'soporte@andando.do',
      documents: documents,
    );
  }
}