import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/inputs/app_select_field.dart';
import '../../../../shared/widgets/provider_bottom_nav.dart';
import '../../../auth/application/auth_controller.dart';
import '../models/provider_settings_model.dart';
import '../services/provider_settings_service.dart';

class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  static const int _maximumFileSize = 5 * 1024 * 1024;

  static const List<String> _provinces = [
    'Distrito Nacional',
    'Azua',
    'Bahoruco',
    'Barahona',
    'Dajabón',
    'Duarte',
    'El Seibo',
    'Elías Piña',
    'Espaillat',
    'Hato Mayor',
    'Hermanas Mirabal',
    'Independencia',
    'La Altagracia',
    'La Romana',
    'La Vega',
    'María Trinidad Sánchez',
    'Monseñor Nouel',
    'Monte Cristi',
    'Monte Plata',
    'Pedernales',
    'Peravia',
    'Puerto Plata',
    'Samaná',
    'San Cristóbal',
    'San José de Ocoa',
    'San Juan',
    'San Pedro de Macorís',
    'Sánchez Ramírez',
    'Santiago',
    'Santiago Rodríguez',
    'Santo Domingo',
    'Valverde',
  ];

  final ProviderSettingsService _service = const ProviderSettingsService();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  ProviderSettingsModel? _settings;
  String _province = '';
  String? _error;

  PlatformFile? _businessLicense;
  PlatformFile? _insurancePolicy;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final settings = await _service.getSettings(
        token: widget.authController.token,
      );

      if (!mounted) return;

      _applySettings(settings);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applySettings(ProviderSettingsModel settings) {
    setState(() {
      _settings = settings;
      _phoneController.text = settings.phone;
      _cityController.text = settings.city;
      _province = settings.province;
      _error = null;
    });
  }

  Future<void> _saveContact() async {
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();

    if (phone.isEmpty || city.isEmpty || _province.isEmpty) {
      _showMessage('Completa teléfono, ciudad y provincia.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final settings = await _service.updateSettings(
        token: widget.authController.token,
        phone: phone,
        city: city,
        province: _province,
      );

      if (!mounted) return;

      _applySettings(settings);
      _showMessage('Datos de contacto actualizados.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickOptionalDocument(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    if (file.bytes == null) {
      _showMessage('No se pudo leer el archivo seleccionado.', isError: true);
      return;
    }

    if (file.size > _maximumFileSize) {
      _showMessage(
        'El archivo supera el máximo permitido de 5MB.',
        isError: true,
      );
      return;
    }

    setState(() {
      if (type == 'business_license') {
        _businessLicense = file;
      }

      if (type == 'insurance_policy') {
        _insurancePolicy = file;
      }
    });
  }

  Future<void> _uploadDocuments() async {
    if (_businessLicense == null && _insurancePolicy == null) {
      _showMessage('Selecciona al menos un documento.', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final settings = await _service.uploadOptionalDocuments(
        token: widget.authController.token,
        businessLicense: _businessLicense,
        insurancePolicy: _insurancePolicy,
      );

      if (!mounted) return;

      setState(() {
        _businessLicense = null;
        _insurancePolicy = null;
      });

      _applySettings(settings);
      _showMessage('Documentos enviados correctamente.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _openDocument(String? url) async {
    if (url == null || url.trim().isEmpty) {
      _showMessage('El archivo no está disponible.', isError: true);
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!launched && mounted) {
      _showMessage('No se pudo abrir el documento.', isError: true);
    }
  }

  PlatformFile? _selectedFile(String type) {
    if (type == 'business_license') {
      return _businessLicense;
    }

    if (type == 'insurance_policy') {
      return _insurancePolicy;
    }

    return null;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB91C1C)
            : const Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.goNamed(RouteNames.providerProfile);
          },
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver al perfil',
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: ProviderBottomNav(
        authController: widget.authController,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_error != null && _settings == null) {
      return _SettingsError(message: _error!, onRetry: _loadSettings);
    }

    final settings = _settings;

    if (settings == null) {
      return _SettingsError(
        message: 'No se pudo cargar la configuración.',
        onRetry: _loadSettings,
      );
    }

    final hasSelectedDocuments =
        _businessLicense != null || _insurancePolicy != null;

    return RefreshIndicator(
      onRefresh: () => _loadSettings(showLoading: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SettingsHeader(),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Datos de contacto',
              subtitle: 'Actualiza la información visible para tus clientes.',
              child: Column(
                children: [
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: 'Teléfono de contacto',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cityController,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(
                      label: 'Ciudad',
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppSelectField(
                    label: 'Provincia',
                    value: _province,
                    placeholder: 'Seleccionar provincia',
                    options: _provinceOptions(),
                    onChanged: (value) {
                      setState(() {
                        _province = value ?? '';
                      });
                    },
                    height: 56,
                    maxMenuHeight: 330,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveContact,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Guardando...' : 'Guardar cambios',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Documentos',
              subtitle:
                  'Consulta los documentos entregados durante tu registro.',
              child: Column(
                children: [
                  for (final document in settings.documents) ...[
                    _DocumentCard(
                      document: document,
                      selectedFile: _selectedFile(document.type),
                      onView: document.viewUrl == null
                          ? null
                          : () => _openDocument(document.viewUrl),
                      onDownload: document.downloadUrl == null
                          ? null
                          : () => _openDocument(document.downloadUrl),
                      onPick: document.canUpload
                          ? () => _pickOptionalDocument(document.type)
                          : null,
                    ),
                    if (document != settings.documents.last)
                      const SizedBox(height: 14),
                  ],
                  if (hasSelectedDocuments) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isUploading ? null : _uploadDocuments,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isUploading
                              ? 'Subiendo...'
                              : 'Subir documentos seleccionados',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppSelectOption> _provinceOptions() {
    final values = [..._provinces];

    if (_province.isNotEmpty && !values.contains(_province)) {
      values.insert(0, _province);
    }

    return values
        .map((province) => AppSelectOption(value: province, label: province))
        .toList();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu cuenta de afiliado',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Administra tus datos de contacto y documentación.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.selectedFile,
    required this.onView,
    required this.onDownload,
    required this.onPick,
  });

  final ProviderSettingsDocument document;
  final PlatformFile? selectedFile;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final uploaded = document.isUploaded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: uploaded ? const Color(0xFFF8FAFC) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: uploaded ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: uploaded
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  uploaded
                      ? Icons.description_outlined
                      : Icons.upload_file_outlined,
                  color: uploaded
                      ? AppColors.primaryBlue
                      : const Color(0xFFA16207),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.label,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uploaded
                          ? document.originalName ?? 'Documento cargado'
                          : document.isRequired
                          ? 'Documento no disponible'
                          : 'Documento opcional pendiente',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    if (uploaded && document.sizeBytes > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatFileSize(document.sizeBytes),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (uploaded) _StatusBadge(status: document.status),
            ],
          ),
          if (uploaded) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Ver'),
                ),
                OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Descargar'),
                ),
              ],
            ),
          ] else if (document.canUpload) ...[
            const SizedBox(height: 14),
            if (selectedFile != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedFile!.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                selectedFile == null
                    ? 'Seleccionar archivo'
                    : 'Cambiar selección',
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';

    final kilobytes = bytes / 1024;

    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }

    final megabytes = kilobytes / 1024;
    return '${megabytes.toStringAsFixed(1)} MB';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = status?.trim().toLowerCase() ?? '';

    final Color background;
    final Color foreground;
    final String label;

    switch (normalized) {
      case 'approved':
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF166534);
        label = 'Aprobado';
      case 'rejected':
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFF991B1B);
        label = 'Rechazado';
      default:
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFF92400E);
        label = 'En revisión';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.primaryBlue,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
