import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/customer_bottom_navigation.dart';

class CustomerHelpCenterScreen extends StatefulWidget {
  const CustomerHelpCenterScreen({super.key});

  @override
  State<CustomerHelpCenterScreen> createState() =>
      _CustomerHelpCenterScreenState();
}

class _CustomerHelpCenterScreenState extends State<CustomerHelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  String? _activeCategory;
  String? _openItemKey;

  final List<_HelpCategory> _categories = const [
    _HelpCategory(
      title: 'Reservas',
      icon: Icons.calendar_month_outlined,
      iconColor: Color(0xFF003B73),
      iconBackground: Color(0xFFEFF6FF),
      items: [
        _HelpFaq(
          question: '¿Cómo hago una reserva?',
          answer:
              'Busca la experiencia que te interese, selecciona la fecha y número de personas, y completa el pago. Recibirás una confirmación por email inmediatamente.',
        ),
        _HelpFaq(
          question: '¿Puedo cancelar mi reserva?',
          answer:
              'Sí, puedes cancelar hasta 24 horas antes del inicio de la experiencia y recibir un reembolso completo. Cancelaciones dentro de las 24 horas no son reembolsables.',
        ),
        _HelpFaq(
          question: '¿Cómo cambio la fecha de mi reserva?',
          answer:
              'Ingresa a Mis Reservas, selecciona la reserva y toca Cambiar fecha. Los cambios están sujetos a disponibilidad.',
        ),
      ],
    ),
    _HelpCategory(
      title: 'Pagos',
      icon: Icons.description_outlined,
      iconColor: Color(0xFF16A34A),
      iconBackground: Color(0xFFDCFCE7),
      items: [
        _HelpFaq(
          question: '¿Qué métodos de pago aceptan?',
          answer:
              'Aceptamos tarjetas Visa, Mastercard, American Express y Discover. Los pagos estarán protegidos mediante integración segura con Azul.',
        ),
        _HelpFaq(
          question: '¿Cuándo recibiré mi reembolso?',
          answer:
              'Los reembolsos se procesan en función de la política de cancelación de la experiencia y del método de pago utilizado.',
        ),
      ],
    ),
    _HelpCategory(
      title: 'Experiencias',
      icon: Icons.star_border_rounded,
      iconColor: Color(0xFFD97706),
      iconBackground: Color(0xFFFFF7ED),
      items: [
        _HelpFaq(
          question: '¿Qué incluye el precio?',
          answer:
              'Cada experiencia detalla lo que incluye en su descripción. Generalmente puede incluir guía, seguro de viajero y elementos indicados por el proveedor.',
        ),
        _HelpFaq(
          question: '¿Puedo dejar una reseña?',
          answer:
              'Sí. Después de completar una experiencia podrás calificarla con estrellas y dejar un comentario.',
        ),
      ],
    ),
    _HelpCategory(
      title: 'Cuenta',
      icon: Icons.help_outline_rounded,
      iconColor: Color(0xFF9333EA),
      iconBackground: Color(0xFFF3E8FF),
      items: [
        _HelpFaq(
          question: '¿Cómo recupero mi contraseña?',
          answer:
              'En la pantalla de inicio de sesión, toca “¿Olvidaste tu contraseña?” y sigue las instrucciones.',
        ),
        _HelpFaq(
          question: '¿Puedo tener múltiples cuentas?',
          answer:
              'Por seguridad recomendamos tener una sola cuenta por persona. Si tienes problemas accediendo, contáctanos.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_HelpCategory> get _filteredCategories {
    final query = _search.trim().toLowerCase();

    return _categories
        .where((category) =>
            _activeCategory == null || category.title == _activeCategory)
        .map((category) {
          if (query.isEmpty) return category;

          final items = category.items.where((item) {
            return item.question.toLowerCase().contains(query) ||
                item.answer.toLowerCase().contains(query);
          }).toList();

          return category.copyWith(items: items);
        })
        .where((category) => category.items.isNotEmpty)
        .toList();
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title estará disponible próximamente.'),
      ),
    );
  }

  Future<void> _openSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'soporte@andando.com.do',
      queryParameters: {
        'subject': 'Soporte AndanDO',
        'body': 'Hola equipo AndanDO,\n\nNecesito ayuda con:\n\n',
      },
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir tu aplicación de correo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Centro de Ayuda',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '¿Cómo podemos ayudarte?',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          const _HelpHero(),
          const SizedBox(height: 20),
          _SearchBox(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _search = value;
                _openItemKey = null;
              });
            },
          ),
          const SizedBox(height: 18),
          if (_search.trim().isEmpty) ...[
            _CategoryChips(
              categories: _categories,
              activeCategory: _activeCategory,
              onSelected: (category) {
                setState(() {
                  _activeCategory =
                      _activeCategory == category ? null : category;
                  _openItemKey = null;
                });
              },
              onAllSelected: () {
                setState(() {
                  _activeCategory = null;
                  _openItemKey = null;
                });
              },
            ),
            const SizedBox(height: 22),
          ],
          if (categories.isEmpty)
            const _EmptyHelpState()
          else
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _FaqCategorySection(
                  category: category,
                  openItemKey: _openItemKey,
                  onToggle: (key) {
                    setState(() {
                      _openItemKey = _openItemKey == key ? null : key;
                    });
                  },
                ),
              ),
            ),
          const _SupportTitle(),
          const SizedBox(height: 12),
          _SupportOption(
            icon: Icons.email_outlined,
            title: 'Enviar email',
            subtitle: 'soporte@andando.com.do',
            backgroundColor: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFD97706),
            onTap: _openSupportEmail,
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavigation(
        currentItem: CustomerBottomNavItem.profile,
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF002D62),
            Color(0xFF1A4A8A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(0x22FFFFFF),
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '¿Necesitas ayuda?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Encuentra respuestas rápidas o contáctanos',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar en el centro de ayuda...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF003B73),
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.activeCategory,
    required this.onSelected,
    required this.onAllSelected,
  });

  final List<_HelpCategory> categories;
  final String? activeCategory;
  final ValueChanged<String> onSelected;
  final VoidCallback onAllSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'Todos',
            selected: activeCategory == null,
            onTap: onAllSelected,
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                label: category.title,
                selected: activeCategory == category.title,
                onTap: () => onSelected(category.title),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF003B73),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF6B7280),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF003B73) : const Color(0xFFE5E7EB),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _FaqCategorySection extends StatelessWidget {
  const _FaqCategorySection({
    required this.category,
    required this.openItemKey,
    required this.onToggle,
  });

  final _HelpCategory category;
  final String? openItemKey;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: category.iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                color: category.iconColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              category.title,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(category.items.length, (index) {
              final item = category.items[index];
              final key = '${category.title}-$index';
              final isOpen = openItemKey == key;

              return _FaqTile(
                item: item,
                isOpen: isOpen,
                showDivider: index != category.items.length - 1,
                onTap: () => onToggle(key),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.isOpen,
    required this.showDivider,
    required this.onTap,
  });

  final _HelpFaq item;
  final bool isOpen;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(
                    color: Color(0xFFF3F4F6),
                  ),
                )
              : null,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isOpen
                          ? const Color(0xFF003B73)
                          : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
            if (isOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.answer,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SupportTitle extends StatelessWidget {
  const _SupportTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'CONTACTAR SOPORTE',
      style: TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHelpState extends StatelessWidget {
  const _EmptyHelpState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Color(0xFF9CA3AF),
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'No encontramos resultados',
            style: TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Intenta buscar con otras palabras.',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCategory {
  const _HelpCategory({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final List<_HelpFaq> items;

  _HelpCategory copyWith({
    List<_HelpFaq>? items,
  }) {
    return _HelpCategory(
      title: title,
      icon: icon,
      iconColor: iconColor,
      iconBackground: iconBackground,
      items: items ?? this.items,
    );
  }
}

class _HelpFaq {
  const _HelpFaq({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}