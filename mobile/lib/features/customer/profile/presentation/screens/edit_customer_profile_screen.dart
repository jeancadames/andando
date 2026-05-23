import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/customer_profile_controller.dart';

/// Pantalla para editar la información personal del cliente.
///
/// Esta pantalla NO necesita AuthController porque aquí no se cierra sesión.
/// Solo utiliza CustomerProfileController para:
/// - cargar el perfil actual.
/// - llenar el formulario.
/// - guardar cambios en backend.
class EditCustomerProfileScreen extends StatefulWidget {
  const EditCustomerProfileScreen({super.key});

  @override
  State<EditCustomerProfileScreen> createState() =>
      _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final CustomerProfileController _controller;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _residenceCityController = TextEditingController();
  final _countryController = TextEditingController();

  String? _gender;
  String _preferredCurrency = 'DOP';
  String _language = 'es';

  @override
  void initState() {
    super.initState();

    /// Este controller puede construirse sin AuthController
    /// porque la pantalla de edición no ejecuta logout().
    _controller = CustomerProfileController();

    _loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();

    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _nationalityController.dispose();
    _residenceCityController.dispose();
    _countryController.dispose();

    super.dispose();
  }

  /// Carga el perfil y llena los campos del formulario.
  Future<void> _loadProfile() async {
    await _controller.loadProfile();

    final user = _controller.user;

    if (!mounted || user == null) return;

    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
    _birthDateController.text = user.birthDate ?? '';
    _nationalityController.text = user.nationality ?? '';
    _residenceCityController.text = user.residenceCity ?? '';
    _countryController.text = user.country ?? '';

    _gender = user.gender;
    _preferredCurrency = user.preferredCurrency ?? 'DOP';
    _language = user.language ?? 'es';

    setState(() {});
  }

  /// Abre date picker y guarda fecha en formato YYYY-MM-DD.
  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final currentValue = _birthDateController.text.trim();

    final initialDate = DateTime.tryParse(currentValue) ??
        DateTime(
          now.year - 20,
          now.month,
          now.day,
        );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(
        now.year,
        now.month,
        now.day - 1,
      ),
    );

    if (selectedDate == null) return;

    _birthDateController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';

    setState(() {});
  }

  /// Guarda los cambios del perfil.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.updateProfile(
      name: _nameController.text.trim(),
      phone: _emptyToNull(_phoneController.text),
      birthDate: _emptyToNull(_birthDateController.text),
      gender: _gender,
      nationality: _emptyToNull(_nationalityController.text),
      residenceCity: _emptyToNull(_residenceCityController.text),
      preferredCurrency: _preferredCurrency,
      language: _language,
      country: _emptyToNull(_countryController.text),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
        ),
      );

      context.pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ?? 'No se pudo actualizar el perfil.',
        ),
      ),
    );
  }

  /// Convierte textos vacíos a null antes de enviarlos al backend.
  String? _emptyToNull(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F7F9),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Editar perfil',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF111827),
              ),
            ),
          ),
          body: _buildBody(),
          bottomNavigationBar: _buildSaveButton(),
        );
      },
    );
  }

  /// Construye el cuerpo según estado:
  /// - cargando
  /// - error
  /// - formulario
  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_controller.errorMessage != null && _controller.profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _controller.errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        children: [
          _SectionCard(
            title: 'Información personal',
            children: [
              _ProfileTextField(
                label: 'Nombre completo',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              _ProfileTextField(
                label: 'Teléfono',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _ProfileTextField(
                label: 'Fecha de nacimiento',
                controller: _birthDateController,
                icon: Icons.cake_outlined,
                readOnly: true,
                onTap: _selectBirthDate,
              ),
              const SizedBox(height: 14),
              _ProfileDropdown<String>(
                label: 'Género',
                value: _gender,
                icon: Icons.wc_rounded,
                hint: 'Seleccionar',
                items: const [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text('Femenino'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Otro'),
                  ),
                  DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefiero no decirlo'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Ubicación y preferencias',
            children: [
              _ProfileTextField(
                label: 'Nacionalidad',
                controller: _nationalityController,
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 14),
              _ProfileTextField(
                label: 'Ciudad de residencia',
                controller: _residenceCityController,
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 14),
              _ProfileTextField(
                label: 'País',
                controller: _countryController,
                icon: Icons.public_rounded,
              ),
              const SizedBox(height: 14),
              _ProfileDropdown<String>(
                label: 'Moneda preferida',
                value: _preferredCurrency,
                icon: Icons.payments_outlined,
                items: const [
                  DropdownMenuItem(
                    value: 'DOP',
                    child: Text('DOP - Peso dominicano'),
                  ),
                  DropdownMenuItem(
                    value: 'USD',
                    child: Text('USD - Dólar estadounidense'),
                  ),
                  DropdownMenuItem(
                    value: 'EUR',
                    child: Text('EUR - Euro'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _preferredCurrency = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _ProfileDropdown<String>(
                label: 'Idioma',
                value: _language,
                icon: Icons.language_rounded,
                items: const [
                  DropdownMenuItem(
                    value: 'es',
                    child: Text('Español'),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('Inglés'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _language = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Botón fijo inferior para guardar cambios.
  Widget _buildSaveButton() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _controller.isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF99BDB9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child: _controller.isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Guardar cambios',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Tarjeta contenedora para secciones del formulario.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Campo de texto reutilizable para editar perfil.
class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF0F766E),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

/// Dropdown reutilizable para editar perfil.
class _ProfileDropdown<T> extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF0F766E),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}