class CustomerLegalSettingsModel {
  final String? termsAcceptedAt;
  final String? termsAcceptedLabel;
  final String termsVersion;
  final String privacyVersion;
  final String cookiesVersion;
  final String rnc;
  final String supportEmail;

  const CustomerLegalSettingsModel({
    required this.termsAcceptedAt,
    required this.termsAcceptedLabel,
    required this.termsVersion,
    required this.privacyVersion,
    required this.cookiesVersion,
    required this.rnc,
    required this.supportEmail,
  });

  factory CustomerLegalSettingsModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] ?? {});

    return CustomerLegalSettingsModel(
      termsAcceptedAt: data['terms_accepted_at']?.toString(),
      termsAcceptedLabel: data['terms_accepted_label']?.toString(),
      termsVersion: data['terms_version']?.toString() ?? 'v1.0',
      privacyVersion: data['privacy_version']?.toString() ?? 'v1.0',
      cookiesVersion: data['cookies_version']?.toString() ?? 'v1.0',
      rnc: data['rnc']?.toString() ?? '',
      supportEmail: data['support_email']?.toString() ?? 'soporte@andando.com.do',
    );
  }
}