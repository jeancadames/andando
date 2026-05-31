import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_controller.dart';
import '../services/provider_experience_reviews_service.dart';

class ProviderExperienceReviewsScreen extends StatefulWidget {
  final AuthController authController;
  final int experienceId;
  final String? initialTitle;

  const ProviderExperienceReviewsScreen({
    super.key,
    required this.authController,
    required this.experienceId,
    this.initialTitle,
  });

  @override
  State<ProviderExperienceReviewsScreen> createState() =>
      _ProviderExperienceReviewsScreenState();
}

class _ProviderExperienceReviewsScreenState
    extends State<ProviderExperienceReviewsScreen> {
  final ProviderExperienceReviewsService _service =
      ProviderExperienceReviewsService();

  final TextEditingController _replyController = TextEditingController();

  ProviderExperienceReviewSummary? _summary;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isDeleting = false;
  String? _errorMessage;
  int? _replyingToReviewId;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _service.getReviews(
        experienceId: widget.experienceId,
        token: widget.authController.token,
      );

      debugPrint('REVIEWS EXPERIENCE ID: ${widget.experienceId}');
      debugPrint('REVIEWS TOTAL: ${summary.totalReviews}');
      debugPrint('REVIEWS LIST LENGTH: ${summary.reviews.length}');
      debugPrint('REVIEWS TITLE: ${summary.experienceTitle}');

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error, stackTrace) {
      debugPrint('ERROR CARGANDO RESEÑAS: $error');
      debugPrint('STACKTRACE RESEÑAS: $stackTrace');

      if (!mounted) return;

      setState(() {
        _summary = null;
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _sendReply(ProviderExperienceReview review) async {
    final text = _replyController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una respuesta antes de enviarla.'),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _service.replyToReview(
        experienceId: widget.experienceId,
        reviewId: review.id,
        responseText: text,
        token: widget.authController.token,
      );

      if (!mounted) return;

      _replyController.clear();

      setState(() {
        _replyingToReviewId = null;
      });

      await _loadReviews();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            review.response == null
                ? 'Respuesta enviada correctamente.'
                : 'Respuesta actualizada correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _deleteReply(ProviderExperienceReview review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar respuesta'),
          content: const Text(
            '¿Seguro que deseas eliminar tu respuesta a esta reseña?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _service.deleteReply(
        experienceId: widget.experienceId,
        reviewId: review.id,
        token: widget.authController.token,
      );

      if (!mounted) return;

      _replyController.clear();

      setState(() {
        _replyingToReviewId = null;
      });

      await _loadReviews();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respuesta eliminada correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _startReply(ProviderExperienceReview review) {
    setState(() {
      _replyingToReviewId = review.id;
      _replyController.text = review.response?.text ?? '';
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToReviewId = null;
      _replyController.clear();
    });
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    context.go('/provider/catalog');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
        ),
        title: Text(
          'Reseñas',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadReviews,
      );
    }

    final summary = _summary;

    if (summary == null) {
      return _ErrorState(
        message: 'No pudimos cargar las reseñas.',
        onRetry: _loadReviews,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ReviewsHeader(
            summary: summary,
            fallbackTitle: widget.initialTitle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: summary.reviews.isEmpty
                ? const _EmptyReviewsState()
                : Column(
                    children: summary.reviews.map((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ReviewCard(
                          review: review,
                          isReplying: _replyingToReviewId == review.id,
                          replyController: _replyController,
                          isSending: _isSending,
                          isDeleting: _isDeleting,
                          onReply: () => _startReply(review),
                          onEditReply: () => _startReply(review),
                          onDeleteReply: () => _deleteReply(review),
                          onCancel: _cancelReply,
                          onSend: () => _sendReply(review),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsHeader extends StatelessWidget {
  final ProviderExperienceReviewSummary summary;
  final String? fallbackTitle;

  const _ReviewsHeader({
    required this.summary,
    required this.fallbackTitle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final title = summary.experienceTitle.trim().isNotEmpty
        ? summary.experienceTitle
        : fallbackTitle ?? 'Experiencia';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.totalReviews} reseñas',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE8E8E8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 86,
                  child: Column(
                    children: [
                      Text(
                        summary.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: primary,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      _StarsRow(
                        rating: summary.averageRating.round(),
                        size: 15,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'de 5',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: summary.ratingDistribution.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _RatingDistributionRow(item: item),
                      );
                    }).toList(),
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

class _RatingDistributionRow extends StatelessWidget {
  final ProviderRatingDistribution item;

  const _RatingDistributionRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((item.percentage / 100).clamp(0.0, 1.0)).toDouble();

    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Row(
            children: [
              Text(
                item.stars.toString(),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.star,
                size: 13,
                color: Colors.amber,
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE5E7EB),
              color: Colors.amber,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            item.count.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ProviderExperienceReview review;
  final bool isReplying;
  final TextEditingController replyController;
  final bool isSending;
  final bool isDeleting;
  final VoidCallback onReply;
  final VoidCallback onEditReply;
  final VoidCallback onDeleteReply;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _ReviewCard({
    required this.review,
    required this.isReplying,
    required this.replyController,
    required this.isSending,
    required this.isDeleting,
    required this.onReply,
    required this.onEditReply,
    required this.onDeleteReply,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: primary,
                  child: Text(
                    review.clientInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _StarsRow(
                            rating: review.rating,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDate(review.date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((review.comment ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          review.comment!.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isReplying)
              _ReplyEditor(
                controller: replyController,
                isSending: isSending,
                onCancel: onCancel,
                onSend: onSend,
              )
            else if (review.response != null)
              _ProviderResponseBox(
                response: review.response!,
                isDeleting: isDeleting,
                onEdit: onEditReply,
                onDelete: onDeleteReply,
              )
            else
              TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.mode_comment_outlined, size: 18),
                label: const Text('Responder'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');

    if (parsed == null) {
      return '';
    }

    final local = parsed.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

class _ProviderResponseBox extends StatelessWidget {
  final ProviderReviewResponse response;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProviderResponseBox({
    required this.response,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.message_outlined,
            color: primary,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respuesta del afiliado',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  response.text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: isDeleting ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: isDeleting ? null : onDelete,
                      icon: isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.delete_outline, size: 16),
                      label: Text(isDeleting ? 'Eliminando...' : 'Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _ReplyEditor({
    required this.controller,
    required this.isSending,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Escribe tu respuesta...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                isSending ? 'Enviando...' : 'Enviar respuesta',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: isSending ? null : onCancel,
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int rating;
  final double size;

  const _StarsRow({
    required this.rating,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0, 5).toInt();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index < safeRating;

        return Icon(
          active ? Icons.star : Icons.star_border,
          size: size,
          color: active ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }
}

class _EmptyReviewsState extends StatelessWidget {
  const _EmptyReviewsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.star_border,
            size: 42,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'Aún no hay reseñas para esta experiencia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Cuando los clientes completen un viaje y dejen su opinión, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 44,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}