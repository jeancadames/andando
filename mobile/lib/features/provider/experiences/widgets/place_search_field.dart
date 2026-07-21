import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place_search_result.dart';
import '../services/provider_experience_service.dart';

class PlaceSearchField extends StatefulWidget {
  final ProviderExperienceService service;
  final String? token;
  final String label;
  final String hint;
  final ValueChanged<PlaceSearchResult> onSelected;

  const PlaceSearchField({
    super.key,
    required this.service,
    required this.token,
    required this.label,
    required this.hint,
    required this.onSelected,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;

  bool _loading = false;
  bool _hasSearched = false;

  List<PlaceSearchResult> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search(value);
    });
  }

  Future<void> _search(String value) async {
    final query = value.trim();

    if (query.length < 3) {
      if (!mounted) return;

      setState(() {
        _results = [];
        _loading = false;
        _hasSearched = false;
      });

      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final results = await widget.service.searchPlaces(
        token: widget.token,
        query: query,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _results = [];
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  void _select(PlaceSearchResult place) {
    _controller.text = place.address.isNotEmpty ? place.address : place.name;

    setState(() {
      _results = [];
    });

    FocusScope.of(context).unfocus();

    widget.onSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
        ),

        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),

          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _results[index];

                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    place.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _select(place),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Google Maps',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5E5E5E),
              ),
            ),
          ),
        ],

        if (_hasSearched &&
            !_loading &&
            _results.isEmpty &&
            query.length >= 3) ...[
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No encontramos coincidencias',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Prueba con otro nombre o una dirección más específica.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],

        if (!_loading && query.isNotEmpty && query.length < 3) ...[
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'Escribe al menos 3 caracteres para buscar ubicaciones.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ],
    );
  }
}
