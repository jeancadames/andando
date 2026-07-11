import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import '../../../customer/shared/widgets/customer_bottom_navigation.dart';
import '../controllers/customer_payment_methods_controller.dart';
import '../../data/models/customer_payment_method_model.dart';
import '../../data/models/customer_payment_transaction_model.dart';

/// Pantalla de métodos de pago del cliente.
///
/// Permite:
/// - Ver tarjetas guardadas.
/// - Agregar tarjeta de forma segura.
/// - Establecer tarjeta principal.
/// - Eliminar tarjeta.
///
/// IMPORTANTE:
/// No se guarda número completo ni CVV.
/// Solo se envía al backend:
/// - brand
/// - last4
/// - holder_name
/// - expiry_month
/// - expiry_year
class CustomerPaymentMethodsScreen extends StatefulWidget {
  const CustomerPaymentMethodsScreen({super.key});

  @override
  State<CustomerPaymentMethodsScreen> createState() =>
      _CustomerPaymentMethodsScreenState();
}

class _CustomerPaymentMethodsScreenState
    extends State<CustomerPaymentMethodsScreen> {
  late final CustomerPaymentMethodsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomerPaymentMethodsController();
    _controller.loadPaymentMethods();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAddCardSheet() async {
    _controller.errorMessage = null;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddCardSheet(
          onSubmit:
              ({
                required type,
                required cardNumber,
                required holderName,
                required expiryMonth,
                required expiryYear,
                required cvv,
              }) {
                return _controller.createPaymentMethod(
                  type: type,
                  cardNumber: cardNumber,
                  holderName: holderName,
                  expiryMonth: expiryMonth,
                  expiryYear: expiryYear,
                  cvv: cvv,
                );
              },
        );
      },
    );

    if (!mounted) return;

    if (added == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarjeta guardada correctamente.')),
      );
    } else if (added == false && _controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage!)),
      );
    }
  }

  Future<void> _confirmSetDefault() async {
    final selected = _controller.selectedPaymentMethod;

    if (selected == null || selected.isDefault) return;

    final confirmed = await _showActionSheet(
      icon: Icons.star_rounded,
      iconColor: const Color(0xFF003B73),
      title: '¿Establecer como principal?',
      message:
          'La tarjeta ••${selected.last4} se usará por defecto en tus próximas reservas.',
      confirmText: 'Confirmar',
      confirmColor: const Color(0xFF003B73),
    );

    if (confirmed != true) return;

    final success = await _controller.setDefaultSelectedPaymentMethod();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Tarjeta principal actualizada.'
              : _controller.errorMessage ??
                    'No se pudo actualizar la tarjeta principal.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final selected = _controller.selectedPaymentMethod;

    if (selected == null) return;

    final confirmed = await _showActionSheet(
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFCE1126),
      title: '¿Eliminar tarjeta?',
      message:
          'Se eliminará la tarjeta ••${selected.last4}. Esta acción no se puede deshacer.',
      confirmText: 'Sí, eliminar',
      confirmColor: const Color(0xFFCE1126),
    );

    if (confirmed != true) return;

    final success = await _controller.deleteSelectedPaymentMethod();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Tarjeta eliminada correctamente.'
              : _controller.errorMessage ?? 'No se pudo eliminar la tarjeta.',
        ),
      ),
    );
  }

  Future<bool?> _showActionSheet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final selected = _controller.selectedPaymentMethod;

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
                  'Métodos de Pago',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gestiona tus tarjetas y billeteras',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _controller.loadPaymentMethods,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const _SecurityBanner(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Mis Tarjetas',
                  trailing:
                      '${_controller.paymentMethods.length} tarjeta${_controller.paymentMethods.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 12),
                if (_controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_controller.errorMessage != null &&
                    _controller.paymentMethods.isEmpty)
                  _ErrorState(
                    message: _controller.errorMessage!,
                    onRetry: _controller.loadPaymentMethods,
                  )
                else if (_controller.paymentMethods.isEmpty)
                  const _EmptyCardsState()
                else ...[
                  ...List.generate(_controller.paymentMethods.length, (index) {
                    final method = _controller.paymentMethods[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CreditCardPreview(
                        method: method,
                        isSelected: index == _controller.selectedIndex,
                        onTap: () {
                          _controller.selectPaymentMethod(index);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  _CardDots(
                    count: _controller.paymentMethods.length,
                    selectedIndex: _controller.selectedIndex,
                    onTap: _controller.selectPaymentMethod,
                  ),
                  const SizedBox(height: 18),
                  if (selected != null)
                    _SelectedCardActions(
                      method: selected,
                      isSaving: _controller.isSaving,
                      isDeleting: _controller.isDeleting,
                      onSetDefault: _confirmSetDefault,
                      onDelete: _confirmDelete,
                    ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _controller.isSaving ? null : _openAddCardSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar Nueva Tarjeta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003B73),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF7EA0C4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _AcceptedNetworks(),
                const SizedBox(height: 26),
                _RecentTransactionsSection(
                  transactions: _controller.transactions,
                ),
              ],
            ),
          ),
          bottomNavigationBar: const CustomerBottomNavigation(
            currentItem: CustomerBottomNavItem.profile,
          ),
        );
      },
    );
  }
}

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002D62), Color(0xFF1A4A8A)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(0x22FFFFFF),
            child: Icon(Icons.shield_outlined, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagos 100% Seguros',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Tus tarjetas se registran directamente en la plataforma Azul. AndanDO solo guarda un token seguro.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: Colors.white38),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF6B7280),
            letterSpacing: 0.7,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _CreditCardPreview extends StatefulWidget {
  const _CreditCardPreview({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final CustomerPaymentMethodModel method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CreditCardPreview> createState() => _CreditCardPreviewState();
}

class _CreditCardPreviewState extends State<_CreditCardPreview> {
  bool _isFlipped = false;

  void _handleTap() {
    widget.onTap();
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _cardColorsByBrand(widget.method.brand);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: widget.isSelected ? 1 : 0.65,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: widget.isSelected ? 1 : 0.97,
        child: Column(
          children: [
            GestureDetector(
              onTap: _handleTap,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _isFlipped ? math.pi : 0),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  final isBack = value > math.pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(value),
                    child: isBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _CardBack(
                              method: widget.method,
                              colors: colors,
                            ),
                          )
                        : _CardFront(method: widget.method, colors: colors),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.method.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Principal',
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  _isFlipped
                      ? 'Toca la tarjeta para ver el frente'
                      : 'Toca la tarjeta para ver el reverso',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.method, required this.colors});

  final CustomerPaymentMethodModel method;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(colors),
      child: Stack(
        children: [
          const _CardDecorations(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _ChipIcon(),
                  const Spacer(),
                  _CardBrandLogo(brand: method.brand),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _MaskedBlock(),
                  const SizedBox(width: 14),
                  _MaskedBlock(),
                  const SizedBox(width: 14),
                  _MaskedBlock(),
                  const SizedBox(width: 14),
                  Text(
                    method.last4,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _CardSmallLabel(
                      label: 'Titular',
                      value: method.holderName,
                    ),
                  ),
                  _CardSmallLabel(
                    label: 'Vence',
                    value: method.expiryLabel,
                    alignEnd: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.method, required this.colors});

  final CustomerPaymentMethodModel method;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: _cardDecoration(colors),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const _CardDecorations(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 34),
              Container(height: 42, color: Colors.black.withOpacity(0.45)),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 150,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'CVV',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '•••',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _CardBrandLogo(brand: method.brand),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaskedBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      '••••',
      style: TextStyle(color: Colors.white54, fontSize: 18, letterSpacing: 3),
    );
  }
}

class _CardDecorations extends StatelessWidget {
  const _CardDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -34,
          top: -42,
          child: Container(
            width: 130,
            height: 130,
            decoration: const BoxDecoration(
              color: Color(0x11FFFFFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -28,
          bottom: -36,
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0x11FFFFFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipIcon extends StatelessWidget {
  const _ChipIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: List.generate(
            4,
            (_) => Container(
              width: 7,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0x8878350F),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBrandLogo extends StatelessWidget {
  const _CardBrandLogo({required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    final normalized = brand.toLowerCase();

    if (normalized == 'mastercard') {
      return SizedBox(
        width: 44,
        height: 28,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB001B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 16,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF79E1B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (normalized == 'amex') {
      return const Text(
        'AMEX',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1,
        ),
      );
    }

    if (normalized == 'discover') {
      return const Text(
        'DISC',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
          letterSpacing: 1,
        ),
      );
    }

    return const Text(
      'VISA',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: 20,
        letterSpacing: 1,
      ),
    );
  }
}

class _CardSmallLabel extends StatelessWidget {
  const _CardSmallLabel({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _CardDots extends StatelessWidget {
  const _CardDots({
    required this.count,
    required this.selectedIndex,
    required this.onTap,
  });

  final int count;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == selectedIndex;

        return GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 22 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF003B73)
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _SelectedCardActions extends StatelessWidget {
  const _SelectedCardActions({
    required this.method,
    required this.isSaving,
    required this.isDeleting,
    required this.onSetDefault,
    required this.onDelete,
  });

  final CustomerPaymentMethodModel method;
  final bool isSaving;
  final bool isDeleting;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Text(
                  'Tarjeta ••${method.last4}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: method.isDefault
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    method.isDefault ? 'Principal' : 'Secundaria',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: method.isDefault
                          ? const Color(0xFF166534)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!method.isDefault)
            _ActionTile(
              icon: Icons.star_outline_rounded,
              iconColor: const Color(0xFF003B73),
              title: 'Establecer como principal',
              enabled: !isSaving,
              onTap: onSetDefault,
            ),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFCE1126),
            title: isDeleting ? 'Eliminando...' : 'Eliminar tarjeta',
            enabled: !isDeleting,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withOpacity(0.08),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFF3F4F6),
            child: Icon(
              Icons.credit_card_rounded,
              color: Color(0xFF9CA3AF),
              size: 34,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'No tienes tarjetas guardadas',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptedNetworks extends StatelessWidget {
  const _AcceptedNetworks();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: const [
        _NetworkBadge(label: 'VISA'),
        _NetworkBadge(label: 'MC'),
        _NetworkBadge(label: 'AMEX'),
        _NetworkBadge(label: 'DISC'),
      ],
    );
  }
}

class _NetworkBadge extends StatelessWidget {
  const _NetworkBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({required this.transactions});

  final List<CustomerPaymentTransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Transacciones Recientes'),
        const SizedBox(height: 12),

        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(height: 12),
                Text(
                  'Aún no tienes transacciones',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: transactions.map((transaction) {
                return _TransactionTile(
                  item: _TransactionItem(
                    title: transaction.title,
                    date: transaction.dateLabel ?? '',
                    amount: transaction.amount,
                    card: transaction.paymentMethodLabel ?? '',
                    status: transaction.statusLabel,
                    statusColor: _statusColor(transaction.status),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF16A34A);

      case 'cancelled':
        return const Color(0xFFDC2626);

      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

class _TransactionItem {
  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.card,
    required this.status,
    required this.statusColor,
  });

  final String title;
  final String date;
  final double amount;
  final String card;
  final String status;
  final Color statusColor;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final _TransactionItem item;

  @override
  Widget build(BuildContext context) {
    final isPositive = item.amount > 0;
    final value = item.amount.abs().toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: isPositive
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFFEEF2),
            child: Icon(
              Icons.credit_card_rounded,
              color: isPositive
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFCE1126),
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.date} · ${item.card}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}RD\$$value',
                style: TextStyle(
                  color: isPositive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.status,
                style: TextStyle(
                  color: item.statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFCE1126),
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

List<Color> _cardColorsByBrand(String brand) {
  switch (brand.toLowerCase()) {
    case 'visa':
      return const [Color(0xFF002D62), Color(0xFF1A4A8A)];
    case 'mastercard':
      return const [Color(0xFF111827), Color(0xFF2D2D4E)];
    case 'amex':
      return const [Color(0xFF006FBA), Color(0xFF2E9AD0)];
    case 'discover':
      return const [Color(0xFFCE1126), Color(0xFF8B0000)];
    default:
      return const [Color(0xFF002D62), Color(0xFF1A4A8A)];
  }
}

BoxDecoration _cardDecoration(List<Color> colors) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  );
}

class AddCardSheet extends StatefulWidget {
  const AddCardSheet({
    super.key,
    required this.onSubmit,
    this.isBookingFlow = false,
  });

  final bool isBookingFlow;

  final Future<bool> Function({
    required String type,
    required String cardNumber,
    required String holderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  })
  onSubmit;

  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet> {
  final _formKey = GlobalKey<FormState>();

  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _type = 'credit';
  bool _isSaving = false;
  bool _showCvv = false;

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final expiryParts = _expiryController.text.split('/');
    final expiryMonth = int.parse(expiryParts[0]);
    final expiryYear = 2000 + int.parse(expiryParts[1]);

    setState(() => _isSaving = true);

    final success = await widget.onSubmit(
      type: _type,
      cardNumber: _numberController.text,
      holderName: _holderController.text,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvv: _cvvController.text,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      _numberController.clear();
      _holderController.clear();
      _expiryController.clear();
      _cvvController.clear();
    }

    Navigator.pop(context, success);
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _formatCardNumber(String value) {
    final digits = _onlyDigits(value);
    final limited = digits.substring(
      0,
      digits.length > 16 ? 16 : digits.length,
    );

    final buffer = StringBuffer();

    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }

      buffer.write(limited[i]);
    }

    return buffer.toString();
  }

  String _formatExpiry(String value) {
    final digits = _onlyDigits(value);
    final limited = digits.substring(0, digits.length > 4 ? 4 : digits.length);

    if (limited.length <= 2) {
      return limited;
    }

    return '${limited.substring(0, 2)}/${limited.substring(2)}';
  }

  void _setFormattedValue(TextEditingController controller, String formatted) {
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Agregar tarjeta',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (widget.isBookingFlow) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD5E7FA),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                color: Color(0xFF003B73),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Agrega una tarjeta para continuar con tu reserva',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Crearemos un token seguro para que puedas utilizar esta tarjeta en futuras transacciones. AndanDO no almacena el número completo de tu tarjeta ni el CVV.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Color(0xFF475569),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Puedes consultar y administrar esta tarjeta desde Perfil → Configuraciones → Métodos de pago.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF003B73),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _type = 'credit'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _type == 'credit'
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF9FAFB),
                            side: BorderSide(
                              color: _type == 'credit'
                                  ? const Color(0xFF003B73)
                                  : const Color(0xFFE5E7EB),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Credito',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _type = 'debit'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _type == 'debit'
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF9FAFB),
                            side: BorderSide(
                              color: _type == 'debit'
                                  ? const Color(0xFF003B73)
                                  : const Color(0xFFE5E7EB),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Debito',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      label: 'Numero de tarjeta',
                      hint: '0000 0000 0000 0000',
                    ),
                    onChanged: (value) {
                      final formatted = _formatCardNumber(value);

                      if (formatted != value) {
                        _setFormattedValue(_numberController, formatted);
                      }
                    },
                    validator: (value) {
                      final digits = _onlyDigits(value ?? '');

                      if (digits.length != 16) {
                        return 'Debe tener 16 digitos.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _holderController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration(
                      label: 'Nombre del titular',
                      hint: 'Como aparece en la tarjeta',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El titular es obligatorio.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'Vencimiento',
                            hint: 'MM/AA',
                          ),
                          onChanged: (value) {
                            final formatted = _formatExpiry(value);

                            if (formatted != value) {
                              _setFormattedValue(_expiryController, formatted);
                            }
                          },
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                              return 'MM/AA';
                            }

                            final month =
                                int.tryParse(value.substring(0, 2)) ?? 0;

                            if (month < 1 || month > 12) {
                              return 'Mes invalido.';
                            }

                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: !_showCvv,
                          decoration: _inputDecoration(
                            label: 'CVV',
                            hint: '***',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _showCvv = !_showCvv);
                              },
                              icon: Icon(
                                _showCvv
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            final digits = _onlyDigits(value);
                            final limited = digits.substring(
                              0,
                              digits.length > 3 ? 3 : digits.length,
                            );

                            if (limited != value) {
                              _setFormattedValue(_cvvController, limited);
                            }
                          },
                          validator: (value) {
                            final digits = _onlyDigits(value ?? '');

                            if (digits.length != 3) {
                              return 'CVV invalido.';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF166534),
                          size: 19,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Tus datos estan protegidos. No guardamos CVV ni numero completo.',
                            style: TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isSaving ? 'Guardando...' : 'Guardar tarjeta',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003B73),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF7EA0C4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF003B73), width: 1.4),
      ),
    );
  }
}
