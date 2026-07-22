class ProviderLegalDocumentModel {
  const ProviderLegalDocumentModel({
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
    required this.statusLabel,
  });

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
  final String statusLabel;

  factory ProviderLegalDocumentModel.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['version']?.toString().trim() ?? '';

    return ProviderLegalDocumentModel(
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
      acceptanceScope: json['acceptance_scope']?.toString() ?? 'informational',
      statusLabel:
          json['status_label']?.toString() ??
          _fallbackStatusLabel(
            type: json['type']?.toString() ?? '',
            accepted: json['accepted'] == true,
          ),
    );
  }

  static String _fallbackStatusLabel({
    required String type,
    required bool accepted,
  }) {
    if (accepted) {
      return type == 'privacy' ? 'Leído' : 'Aceptado';
    }

    switch (type) {
      case 'terms_provider':
      case 'provider_standards':
        return 'Pendiente';
      case 'privacy':
        return 'Pendiente de lectura';
      default:
        return 'Documento informativo';
    }
  }
}

class ProviderLegalSummaryModel {
  const ProviderLegalSummaryModel({
    required this.requiredDocumentsCount,
    required this.acceptedRequiredDocumentsCount,
    required this.allRequiredDocumentsAccepted,
  });

  final int requiredDocumentsCount;
  final int acceptedRequiredDocumentsCount;
  final bool allRequiredDocumentsAccepted;

  factory ProviderLegalSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProviderLegalSummaryModel(
      requiredDocumentsCount:
          int.tryParse(json['required_documents_count']?.toString() ?? '') ?? 0,
      acceptedRequiredDocumentsCount:
          int.tryParse(
            json['accepted_required_documents_count']?.toString() ?? '',
          ) ??
          0,
      allRequiredDocumentsAccepted:
          json['all_required_documents_accepted'] == true,
    );
  }
}

class ProviderLegalSettingsModel {
  const ProviderLegalSettingsModel({
    required this.requiresAction,
    required this.summary,
    required this.documents,
    required this.businessName,
    required this.providerStatus,
    required this.supportEmail,
    required this.commercialEmail,
    required this.operatorName,
    required this.rnc,
  });

  final bool requiresAction;
  final ProviderLegalSummaryModel summary;
  final List<ProviderLegalDocumentModel> documents;

  final String businessName;
  final String providerStatus;

  final String supportEmail;
  final String commercialEmail;

  final String operatorName;
  final String rnc;

  factory ProviderLegalSettingsModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    if (rawData is! Map) {
      throw const FormatException(
        'El servidor respondió con una configuración legal inválida.',
      );
    }

    final data = Map<String, dynamic>.from(rawData);

    final rawSummary = data['summary'];
    final summary = rawSummary is Map
        ? ProviderLegalSummaryModel.fromJson(
            Map<String, dynamic>.from(rawSummary),
          )
        : const ProviderLegalSummaryModel(
            requiredDocumentsCount: 0,
            acceptedRequiredDocumentsCount: 0,
            allRequiredDocumentsAccepted: false,
          );

    final rawDocuments = data['documents'];

    final documents = rawDocuments is List
        ? rawDocuments
              .whereType<Map>()
              .map(
                (document) => ProviderLegalDocumentModel.fromJson(
                  Map<String, dynamic>.from(document),
                ),
              )
              .toList()
        : <ProviderLegalDocumentModel>[];

    final provider = data['provider'] is Map
        ? Map<String, dynamic>.from(data['provider'] as Map)
        : <String, dynamic>{};

    final contact = data['contact'] is Map
        ? Map<String, dynamic>.from(data['contact'] as Map)
        : <String, dynamic>{};

    final corporateNotice = data['corporate_notice'] is Map
        ? Map<String, dynamic>.from(data['corporate_notice'] as Map)
        : <String, dynamic>{};

    return ProviderLegalSettingsModel(
      requiresAction: data['requires_action'] == true,
      summary: summary,
      documents: documents,
      businessName: provider['business_name']?.toString() ?? '',
      providerStatus: provider['status']?.toString() ?? '',
      supportEmail:
          contact['support_email']?.toString() ?? 'soporte@andando.do',
      commercialEmail:
          contact['commercial_email']?.toString() ?? 'comercial@andando.do',
      operatorName:
          corporateNotice['operator_name']?.toString() ??
          'ABC VANTEK GROUP, S.R.L.',
      rnc: corporateNotice['rnc']?.toString() ?? '',
    );
  }
}
