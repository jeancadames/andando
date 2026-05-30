import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../booking/data/models/customer_booking_model.dart';
import '../controllers/create_review_controller.dart';

class CreateReviewScreen extends StatefulWidget {
  const CreateReviewScreen({
    super.key,
    required this.booking,
  });

  final CustomerBookingModel booking;

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final CreateReviewController _controller = CreateReviewController();
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;

  @override
  void initState() {
    super.initState();

    _rating = widget.booking.reviewRating ?? 0;

    final initialComment = widget.booking.reviewComment;
    if (initialComment != null && initialComment.trim().isNotEmpty) {
      _commentController.text = initialComment;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final success = await _controller.submitReview(
      bookingId: widget.booking.id,
      reviewId: widget.booking.reviewId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              onPressed: () => context.pop(false),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              widget.booking.hasReview
                  ? 'Editar Reseña'
                  : 'Calificar Experiencia',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ExperienceHeaderCard(booking: widget.booking),
                      const SizedBox(height: 24),
                      _RatingCard(
                        rating: _rating,
                        onChanged: (value) {
                          setState(() => _rating = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      _CommentCard(controller: _commentController),
                      const SizedBox(height: 24),
                      const _PhotosCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    color: const Color(0xFFF5F5F5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                _controller.isSubmitting || _rating == 0
                                    ? null
                                    : _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _rating > 0
                                  ? const Color(0xFF003B73)
                                  : const Color(0xFF8098B5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _controller.isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    widget.booking.hasReview
                                        ? 'Guardar Cambios'
                                        : 'Publicar Calificación',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 18,
                          child: Text(
                            _controller.errorMessage != null
                                ? _controller.errorMessage!
                                : _rating == 0
                                    ? 'Debes seleccionar al menos una estrella para continuar'
                                    : '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _controller.errorMessage != null
                                  ? const Color(0xFF7F1D1D)
                                  : const Color(0xFF5B6472),
                              fontSize: 12,
                              fontWeight: _controller.errorMessage != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
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
}

class _ExperienceHeaderCard extends StatelessWidget {
  const _ExperienceHeaderCard({
    required this.booking,
  });

  final CustomerBookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: booking.coverPhotoUrl == null || booking.coverPhotoUrl!.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(booking.coverPhotoUrl!),
                fit: BoxFit.cover,
              ),
        color: const Color(0xFFD1D5DB),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0xAA000000),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.experienceTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.formattedDate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.rating,
    required this.onChanged,
  });

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        children: [
          const Text(
            '¿Cómo fue tu experiencia?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu opinión ayuda a otros viajeros',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= rating;

              return IconButton(
                onPressed: () => onChanged(value),
                iconSize: 44,
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: selected
                      ? const Color(0xFFFFB703)
                      : const Color(0xFFD1D5DB),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatefulWidget {
  const _CommentCard({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.length;

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuéntanos más',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '¿Qué destacarías de esta experiencia? (opcional)',
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            maxLength: 500,
            maxLines: 6,
            decoration: InputDecoration(
              counterText: '',
              hintText:
                  'Comparte los detalles de tu experiencia: qué te gustó más, qué mejorarías, recomendaciones para otros viajeros...',
              hintStyle: const TextStyle(
                color: Color(0xFF8A92A3),
                height: 1.4,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFD1D5DB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFD1D5DB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF003B73),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count/500 caracteres',
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agrega fotos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Comparte imágenes de tu experiencia (opcional)',
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFDADDE2),
                width: 1.5,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(height: 8),
                Text(
                  'Toca para agregar fotos (0/6)',
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}