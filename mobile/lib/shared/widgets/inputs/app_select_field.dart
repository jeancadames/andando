import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Opción reusable para AppSelectField.
///
/// value:
/// Valor técnico que guardas o envías al backend.
///
/// label:
/// Texto visible para el usuario.
class AppSelectOption {
  const AppSelectOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

/// Dropdown reusable para formularios.
///
/// Características:
/// - Usa el mismo ancho del selector.
/// - Calcula automáticamente si debe abrir arriba o abajo.
/// - No ocupa pantalla completa.
/// - Protege contra valores viejos que ya no existan en la lista.
/// - Tiene altura similar a los ProviderTextField.
/// - Puede usarse en cualquier pantalla.
class AppSelectField extends StatefulWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = 'Seleccionar...',
    this.enabled = true,
    this.height = 50,
    this.itemHeight = 48,
    this.maxMenuHeight = 320,
    this.prefixIcon,
    this.errorText,
    this.showLabel = true,
  });

  final String label;
  final String value;
  final String placeholder;
  final List<AppSelectOption> options;
  final ValueChanged<String?> onChanged;

  final bool enabled;
  final double height;
  final double itemHeight;
  final double maxMenuHeight;
  final IconData? prefixIcon;
  final String? errorText;
  final bool showLabel;

  @override
  State<AppSelectField> createState() => _AppSelectFieldState();
}

class _AppSelectFieldState extends State<AppSelectField> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isDisposing = false;

  static const double _gap = 6;
  static const double _menuVerticalPadding = 12;

  bool get _hasError {
    final error = widget.errorText;
    return error != null && error.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant AppSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enabled && _isOpen) {
      _removeOverlay();
      return;
    }

    if (_isOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _removeOverlay(notify: false);
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled || _isDisposing) return;

    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_isDisposing || !mounted) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final renderObject = _fieldKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final fieldSize = renderObject.size;
    final fieldOffset = renderObject.localToGlobal(Offset.zero);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    final safeTop = mediaQuery.padding.top;
    final bottomInset = math.max(
      mediaQuery.padding.bottom,
      mediaQuery.viewInsets.bottom,
    );

    final availableAbove = fieldOffset.dy - safeTop - _gap;

    final availableBelow = screenHeight -
        fieldOffset.dy -
        fieldSize.height -
        bottomInset -
        _gap;

    final rawMenuHeight = widget.options.isEmpty
        ? widget.itemHeight + _menuVerticalPadding
        : (widget.options.length * widget.itemHeight) + _menuVerticalPadding;

    final desiredHeight = math.min(
      rawMenuHeight,
      widget.maxMenuHeight,
    );

    final shouldOpenBelow =
        availableBelow >= desiredHeight || availableBelow >= availableAbove;

    final availableSpace = math.max(
      0.0,
      shouldOpenBelow ? availableBelow : availableAbove,
    );

    final minVisibleHeight = math.min(
      widget.itemHeight + _menuVerticalPadding,
      desiredHeight,
    );

    final menuHeight = math.max(
      minVisibleHeight,
      math.min(desiredHeight, availableSpace),
    );

    final verticalOffset = shouldOpenBelow
        ? fieldSize.height + _gap
        : -menuHeight - _gap;

    _removeOverlay(notify: false);

    if (!mounted || _isDisposing) return;

    setState(() {
      _isOpen = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, verticalOffset),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: fieldSize.width,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: menuHeight,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.options.isEmpty
                          ? _EmptyOption(
                              height: widget.itemHeight,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shrinkWrap: true,
                              itemCount: widget.options.length,
                              itemBuilder: (context, index) {
                                final option = widget.options[index];
                                final isSelected =
                                    option.value == widget.value;

                                return _OptionTile(
                                  option: option,
                                  isSelected: isSelected,
                                  height: widget.itemHeight,
                                  onTap: () {
                                    _removeOverlay();
                                    widget.onChanged(option.value);
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay({bool notify = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;

    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {
        // El overlay ya pudo haber sido removido por el árbol de Flutter.
      }
    }

    if (!notify || _isDisposing || !mounted) {
      _isOpen = false;
      return;
    }

    if (_isOpen) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final optionExists = widget.options.any(
      (option) => option.value == widget.value,
    );

    final selectedValue =
        widget.value.isEmpty || !optionExists ? null : widget.value;

    final selectedOption = selectedValue == null
        ? null
        : widget.options.firstWhere(
            (option) => option.value == selectedValue,
          );

    final borderColor = _hasError
        ? AppColors.primaryRed
        : _isOpen
            ? AppColors.primaryBlue
            : const Color(0xFFE5E7EB);

    final textColor = widget.enabled
        ? AppColors.textDark
        : AppColors.mutedForeground.withOpacity(0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _fieldKey,
            behavior: HitTestBehavior.opaque,
            onTap: _toggleDropdown,
            child: Container(
              height: widget.height,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? const Color(0xFFF8F9FA)
                    : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: _isOpen || _hasError ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: widget.enabled
                          ? AppColors.mutedForeground
                          : AppColors.mutedForeground.withOpacity(0.60),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      selectedOption?.label ?? widget.placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedOption == null
                            ? const Color(0xFF8A94A6)
                            : textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.enabled
                          ? AppColors.mutedForeground
                          : AppColors.mutedForeground.withOpacity(0.60),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.height,
    required this.onTap,
  });

  final AppSelectOption option;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        color: isSelected
            ? AppColors.primaryBlue.withOpacity(0.08)
            : Colors.transparent,
        child: Text(
          option.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.textDark,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _EmptyOption extends StatelessWidget {
  const _EmptyOption({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 12,
      child: const Center(
        child: Text(
          'No hay opciones disponibles',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}