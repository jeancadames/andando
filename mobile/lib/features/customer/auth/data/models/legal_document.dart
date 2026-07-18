class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.type,
    required this.audience,
    required this.version,
    required this.title,
    required this.content,
    required this.contentFormat,
    required this.checksum,
    required this.requiresAcceptance,
    this.summary,
    this.effectiveAt,
    this.publishedAt,
  });

  final int id;
  final String type;
  final String audience;
  final String version;
  final String title;
  final String? summary;
  final String content;
  final String contentFormat;
  final DateTime? effectiveAt;
  final DateTime? publishedAt;
  final bool requiresAcceptance;
  final String checksum;

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final audience = json['audience'];
    final version = json['version'];
    final title = json['title'];
    final content = json['content'];
    final contentFormat = json['content_format'];
    final checksum = json['checksum'];

    if (id is! num ||
        type is! String ||
        audience is! String ||
        version is! String ||
        title is! String ||
        content is! String ||
        contentFormat is! String ||
        checksum is! String) {
      throw const FormatException(
        'El documento legal recibido tiene un formato inválido.',
      );
    }

    return LegalDocument(
      id: id.toInt(),
      type: type,
      audience: audience,
      version: version,
      title: title,
      summary: json['summary']?.toString(),
      content: content,
      contentFormat: contentFormat,
      effectiveAt: _parseDate(json['effective_at']),
      publishedAt: _parseDate(json['published_at']),
      requiresAcceptance: json['requires_acceptance'] == true,
      checksum: checksum,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  String get effectiveDateLabel {
    final date = effectiveAt;

    if (date == null) {
      return 'Fecha de vigencia no disponible';
    }

    const months = <int, String>{
      1: 'enero',
      2: 'febrero',
      3: 'marzo',
      4: 'abril',
      5: 'mayo',
      6: 'junio',
      7: 'julio',
      8: 'agosto',
      9: 'septiembre',
      10: 'octubre',
      11: 'noviembre',
      12: 'diciembre',
    };

    return '${date.day} de ${months[date.month]} de ${date.year}';
  }
}
