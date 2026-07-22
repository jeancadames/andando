import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/datasources/customer_auth_api.dart';
import '../../../auth/data/models/legal_document.dart';
import '../../../reviews/presentation/widgets/experience_reviews_section.dart';
import '../../data/models/customer_experience_model.dart';
import '../../../booking/data/datasources/customer_booking_remote_datasource.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../../chat/data/services/customer_chat_service.dart';
import '../../../../payments/presentation/controllers/customer_payment_methods_controller.dart';
import '../../../../payments/presentation/screens/customer_payment_methods_screen.dart';

class ExperienceDetailScreen extends StatefulWidget {
  final CustomerExperienceModel experience;
  final AuthController authController;
  final bool initialIsFavorite;
  final int? initialScheduleId;
  final int? initialTravelers;
  final bool openBookingReview;
  final ValueChanged<bool> onFavoriteChanged;

  const ExperienceDetailScreen({
    super.key,
    required this.experience,
    required this.authController,
    required this.initialIsFavorite,
    required this.onFavoriteChanged,
    this.initialScheduleId,
    this.initialTravelers,
    this.openBookingReview = false,
  });

  @override
  State<ExperienceDetailScreen> createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends State<ExperienceDetailScreen> {
  late bool isFavorite;
  late double _currentRating;
  late int _currentReviewsCount;

  int travelers = 1;
  bool includesMinors = false;
  int minorCount = 0;
  bool isReserving = false;

  CustomerExperienceScheduleModel? selectedSchedule;
  String? selectedPickupPoint;

  late List<CustomerExperienceScheduleModel> _availableSchedules;

  late final TextEditingController _travelersController;
  late final CustomerBookingRemoteDataSource _bookingDataSource;
  late final CustomerPaymentMethodsController _paymentMethodsController;

  final CustomerAuthApi _customerAuthApi = const CustomerAuthApi();

  LegalDocument? _paymentPolicyDocument;
  LegalDocument? _waiverDocument;
  LegalDocument? _minorsDocument;

  bool _isLoadingBookingDocuments = false;

  final CustomerChatService _chatService = CustomerChatService();

  bool isOpeningChat = false;

  List<CustomerExperienceScheduleModel> get availableSchedules {
    return _availableSchedules;
  }

  int get maxTravelers {
    if (selectedSchedule != null) {
      return selectedSchedule!.availableSpots;
    }

    if (widget.experience.capacity > 0) {
      return widget.experience.capacity;
    }

    return 20;
  }

  bool get canReserve {
    final hasRequiredPickupPoint =
        !widget.experience.includesTransport ||
        (selectedPickupPoint != null && selectedPickupPoint!.trim().isNotEmpty);

    return selectedSchedule != null &&
      travelers >= 1 &&
      totalParticipants <= maxTravelers &&
      (!includesMinors || minorCount >= 1) &&
      hasRequiredPickupPoint &&
      !isReserving;
  }

  double get unitPrice {
    return selectedSchedule?.price ?? widget.experience.price;
  }

  String get unitCurrency {
    return selectedSchedule?.currency ?? widget.experience.currency;
  }

  int get totalParticipants {
    return travelers + (includesMinors ? minorCount : 0);
  }

  double get totalPrice => unitPrice * totalParticipants;

  String get formattedUnitPrice {
    final formatter = NumberFormat('#,###', 'en_US');
    final formatted = formatter.format(unitPrice);

    if (unitCurrency == 'DOP') {
      return 'RD\$$formatted';
    }

    return '$unitCurrency $formatted';
  }

  Future<bool> _loadBookingLegalDocuments() async {
    if (_paymentPolicyDocument != null &&
        _waiverDocument != null &&
        (!includesMinors || _minorsDocument != null)) {
      return true;
    }

    if (_isLoadingBookingDocuments) {
      return false;
    }

    setState(() {
      _isLoadingBookingDocuments = true;
    });

    try {
      final paymentPolicyFuture = _customerAuthApi.getLegalDocument(
        type: 'payment_policy',
      );

      final waiverFuture = _customerAuthApi.getLegalDocument(type: 'waiver');

      final minorsFuture = includesMinors
          ? _customerAuthApi.getLegalDocument(type: 'minors')
          : Future<LegalDocument?>.value(null);

      final results = await Future.wait<dynamic>([
        paymentPolicyFuture,
        waiverFuture,
        minorsFuture,
      ]);

      if (!mounted) {
        return false;
      }

      setState(() {
        _paymentPolicyDocument = results[0] as LegalDocument;
        _waiverDocument = results[1] as LegalDocument;
        _minorsDocument = results[2] as LegalDocument?;
      });

      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookingDocuments = false;
        });
      }
    }
  }

  Future<void> _showCustomerRequiredForChatDialog() async {
    final isProvider = _isLoggedAsProvider;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Necesitas una cuenta de cliente',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          content: Text(
            isProvider
                ? 'Estás conectado como afiliado. Para contactar a otro afiliado necesitas entrar con una cuenta de cliente.'
                : 'Para comunicarte con el afiliado necesitas crear una cuenta o iniciar sesión como cliente.',
            style: const TextStyle(height: 1.4, color: Color(0xFF475569)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final redirectPath = '/experiences/${widget.experience.id}';

                if (isProvider) {
                  await widget.authController.logout();

                  if (!mounted) return;
                }

                context.goNamed(
                  RouteNames.login,
                  queryParameters: {'redirect': redirectPath},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B73),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(isProvider ? 'Cambiar a cliente' : 'Iniciar sesión'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _contactProvider() async {
    if (isOpeningChat) return;

    if (!_isLoggedAsCustomer) {
      await _showCustomerRequiredForChatDialog();
      return;
    }

    setState(() {
      isOpeningChat = true;
    });

    try {
      final conversation = await _chatService.createOrGetConversation(
        token: widget.authController.token,
        providerExperienceId: widget.experience.id,
      );

      if (!mounted) return;

      context.push('/client/messages/${conversation.id}', extra: conversation);
    } on CustomerChatException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el chat con el afiliado.'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isOpeningChat = false;
      });
    }
  }

  void _goBackFromDetail() {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    context.goNamed(RouteNames.clientExplore);
  }

  String get formattedTotal {
    final formatter = NumberFormat('#,###', 'en_US');
    final formatted = formatter.format(totalPrice);

    if (unitCurrency == 'DOP') {
      return 'RD\$$formatted';
    }

    return '$unitCurrency $formatted';
  }

  String get shareLink {
    final currentHost = Uri.base.origin;

    if (currentHost.contains('andando.app')) {
      return 'https://andando.app/experiences/${widget.experience.id}';
    }

    return '$currentHost/#/experiences/${widget.experience.id}';
  }

  String get shareMessage {
    return 'Mira esta experiencia en AndanDO: ${widget.experience.title}\n$shareLink';
  }

  @override
  void initState() {
    super.initState();

    isFavorite = widget.initialIsFavorite;
    selectedSchedule = null;

    _currentRating = widget.experience.rating;
    _currentReviewsCount = widget.experience.reviewsCount;

    _availableSchedules = List<CustomerExperienceScheduleModel>.from(
      widget.experience.availableSchedules,
    );

    _travelersController = TextEditingController(text: travelers.toString());
    _bookingDataSource = CustomerBookingRemoteDataSource();
    _paymentMethodsController = CustomerPaymentMethodsController();

    _restorePendingBookingSelection();

    if (widget.openBookingReview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reserveExperience();
      });
    }
  }

  @override
  void dispose() {
    _travelersController.dispose();
    _paymentMethodsController.dispose();
    super.dispose();
  }

  bool get _isLoggedAsCustomer {
    final isAuthenticated = widget.authController.isAuthenticated;
    final userType = widget.authController.userType?.trim().toLowerCase() ?? '';
    final token = widget.authController.token?.trim() ?? '';

    return isAuthenticated &&
        token.isNotEmpty &&
        (userType == 'customer' || userType == 'client' || userType == 'user');
  }

  bool get _isLoggedAsProvider {
    final isAuthenticated = widget.authController.isAuthenticated;
    final userType = widget.authController.userType?.trim().toLowerCase() ?? '';

    return isAuthenticated &&
        (userType == 'provider' ||
            userType == 'affiliate' ||
            userType == 'afiliado');
  }

  void _restorePendingBookingSelection() {
    final initialScheduleId = widget.initialScheduleId;

    if (initialScheduleId != null) {
      for (final schedule in _availableSchedules) {
        if (schedule.id == initialScheduleId) {
          selectedSchedule = schedule;
          break;
        }
      }
    }

    final requestedTravelers = widget.initialTravelers;

    if (requestedTravelers != null && requestedTravelers > 0) {
      travelers = requestedTravelers.clamp(1, maxTravelers).toInt();
      _travelersController.text = travelers.toString();
      _travelersController.selection = TextSelection.fromPosition(
        TextPosition(offset: _travelersController.text.length),
      );
    }
  }

  Future<void> _goToAuthKeepingBookingIntent() async {
    final schedule = selectedSchedule;

    if (schedule == null) return;

    final redirectPath = Uri(
      path: '/experiences/${widget.experience.id}',
      queryParameters: {
        'openBookingReview': '1',
        'scheduleId': schedule.id.toString(),
        'travelers': travelers.toString(),
      },
    ).toString();

    if (_isLoggedAsProvider) {
      await widget.authController.logout();

      if (!mounted) return;
    }

    context.goNamed(
      RouteNames.login,
      queryParameters: {'redirect': redirectPath},
    );
  }

  Future<void> _showCustomerRequiredDialog() async {
    final isProvider = _isLoggedAsProvider;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Necesitas una cuenta de cliente',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          content: Text(
            isProvider
                ? 'Estás conectado como afiliado. Para reservar una experiencia necesitas entrar o crear una cuenta de cliente.'
                : 'Para reservar esta experiencia necesitas crear una cuenta o iniciar sesión como cliente. Mantendremos la fecha y la cantidad de viajeros que seleccionaste.',
            style: const TextStyle(height: 1.4, color: Color(0xFF475569)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _goToAuthKeepingBookingIntent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B73),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isLoggedAsProvider ? 'Cambiar a cliente' : 'Crear cuenta',
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    widget.onFavoriteChanged(isFavorite);
  }

  void _updateTravelers(int value) {
    final reservedForMinors = includesMinors ? minorCount : 0;
    final maximumAdults = (maxTravelers - reservedForMinors).clamp(
      1,
      maxTravelers,
    );

    final safeValue = value.clamp(1, maximumAdults);

    setState(() {
      travelers = safeValue;

      _travelersController.text = safeValue.toString();
      _travelersController.selection = TextSelection.fromPosition(
        TextPosition(offset: _travelersController.text.length),
      );
    });
  }

  void _updateIncludesMinors(bool value) {
    setState(() {
      includesMinors = value;

      if (!includesMinors) {
        minorCount = 0;
        return;
      }

      final availableForMinors = maxTravelers - travelers;

      if (availableForMinors < 1) {
        includesMinors = false;
        minorCount = 0;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No quedan cupos disponibles para agregar menores.',
            ),
          ),
        );

        return;
      }

      minorCount = 1;
    });
  }

  void _updateMinorCount(int value) {
    final maximumMinors = maxTravelers - travelers;

    if (maximumMinors < 1) {
      return;
    }

    final safeValue = value.clamp(1, maximumMinors);

    setState(() {
      minorCount = safeValue;
    });
  }

  void _onScheduleChanged(CustomerExperienceScheduleModel? schedule) {
    setState(() {
      selectedSchedule = schedule;

      if (schedule != null) {
      final availableSpots = schedule.availableSpots;

      if (travelers > availableSpots) {
        travelers = availableSpots;
      }

      final availableForMinors = availableSpots - travelers;

      if (includesMinors && availableForMinors < 1) {
        includesMinors = false;
        minorCount = 0;
      } else if (includesMinors && minorCount > availableForMinors) {
        minorCount = availableForMinors;
      }

      _travelersController.text = travelers.toString();
      _travelersController.selection = TextSelection.fromPosition(
        TextPosition(offset: _travelersController.text.length),
      );
    }
    });
  }

  void _decreaseAvailableSpotsAfterBooking() {
    final schedule = selectedSchedule;

    if (schedule == null) return;

    final newAvailableSpots =
    schedule.availableSpots - totalParticipants;

    final updatedSchedule = CustomerExperienceScheduleModel(
      id: schedule.id,
      startsAt: schedule.startsAt,
      capacity: schedule.capacity,
      availableSpots: newAvailableSpots,
      price: schedule.price,
      currency: schedule.currency,
    );

    setState(() {
      if (newAvailableSpots <= 0) {
        _availableSchedules = _availableSchedules
            .where((item) => item.id != schedule.id)
            .toList();

        selectedSchedule = null;
        travelers = 1;
      } else {
        _availableSchedules = _availableSchedules.map((item) {
          if (item.id == schedule.id) {
            return updatedSchedule;
          }

          return item;
        }).toList();

        selectedSchedule = updatedSchedule;

        if (travelers > updatedSchedule.availableSpots) {
          travelers = updatedSchedule.availableSpots;
        }
      }

      _travelersController.text = travelers.toString();
      _travelersController.selection = TextSelection.fromPosition(
        TextPosition(offset: _travelersController.text.length),
      );
    });
  }

  Future<bool> _openAddCardForBooking() async {
    _paymentMethodsController.errorMessage = null;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddCardSheet(
          isBookingFlow: true,
          onSubmit:
              ({
                required type,
                required cardNumber,
                required holderName,
                required expiryMonth,
                required expiryYear,
                required cvv,
              }) {
                return _paymentMethodsController.createPaymentMethod(
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

    if (!mounted) return false;

    if (added == true) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE8F8EE),
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF16A34A),
                size: 36,
              ),
            ),
            title: const Text(
              'Tarjeta registrada',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: const Text(
              'Tu tarjeta fue registrada exitosamente. Ahora continuaremos automáticamente con tu reserva.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Continuar'),
                ),
              ),
            ],
          );
        },
      );

      return true;
    }

    final errorMessage = _paymentMethodsController.errorMessage;

    if (errorMessage != null && errorMessage.trim().isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFFEECEC),
              child: Icon(
                Icons.close_rounded,
                color: Color(0xFFDC2626),
                size: 36,
              ),
            ),
            title: const Text(
              'No pudimos registrar la tarjeta',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Text(
              errorMessage.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Intentar nuevamente'),
                ),
              ),
            ],
          );
        },
      );
    }

    return false;
  }

  Future<void> _reserveExperience({bool skipReview = false}) async {
    if (!canReserve || selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha y cantidad válida de viajeros.'),
        ),
      );
      return;
    }

    if (widget.experience.includesTransport &&
        (selectedPickupPoint == null || selectedPickupPoint!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un punto de recogida antes de reservar.'),
        ),
      );
      return;
    }

    if (!_isLoggedAsCustomer) {
      await _showCustomerRequiredDialog();
      return;
    }

    final legalDocumentsLoaded = await _loadBookingLegalDocuments();

    if (!legalDocumentsLoaded) {
      return;
    }

    final paymentPolicyDocument = _paymentPolicyDocument;
    final waiverDocument = _waiverDocument;
    final minorsDocument = _minorsDocument;

    if (paymentPolicyDocument == null || waiverDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los documentos legales de la reserva.',
          ),
        ),
      );
      return;
    }

    if (includesMinors && minorsDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cargar la declaración para participación de menores.',
          ),
        ),
      );
      return;
    }

    if (!skipReview) {
      final shouldConfirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _BookingReviewDialog(
            experienceTitle: widget.experience.title,
            date: selectedSchedule!.formattedDateTime,
            travelers: totalParticipants,
            includesMinors: includesMinors,
            minorCount: includesMinors ? minorCount : 0,
            duration: widget.experience.displayDuration,
            unitPrice: formattedUnitPrice,
            totalPrice: formattedTotal,
            includedItems: widget.experience.displayAmenities,
            cancellationPolicy: widget.experience.cancellationPolicy,
            paymentPolicyDocument: paymentPolicyDocument,
            waiverDocument: waiverDocument,
            minorsDocument: minorsDocument,
          );
        },
      );

      if (shouldConfirm != true) {
        return;
      }
    }

    setState(() {
      isReserving = true;
    });

    try {
      final reservedTotal = formattedTotal;

      final booking = await _bookingDataSource.createBooking(
        scheduleId: selectedSchedule!.id,
        guestsCount: totalParticipants,
        includesMinors: includesMinors,
        minorCount: includesMinors ? minorCount : 0,
        paymentPolicyDocumentId: paymentPolicyDocument.id,
        paymentPolicyChecksum: paymentPolicyDocument.checksum,
        paymentPolicyAccepted: true,
        waiverDocumentId: waiverDocument.id,
        waiverChecksum: waiverDocument.checksum,
        waiverAccepted: true,
        minorsDocumentId: minorsDocument?.id,
        minorsChecksum: minorsDocument?.checksum,
        minorsAccepted: includesMinors,
        pickupPoint: widget.experience.includesTransport
            ? selectedPickupPoint
            : null,
      );

      _decreaseAvailableSpotsAfterBooking();

      if (!mounted) return;

      final goToBooking = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return _BookingSuccessDialog(
            bookingCode: booking.bookingCode,
            totalPrice: reservedTotal,
          );
        },
      );

      if (goToBooking == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/client/bookings?bookingCode=${booking.bookingCode}');
        });
      }
    } on CustomerBookingException catch (error) {
      if (!mounted) return;

      if (error.code == 'CARD_REQUIRED') {
        final cardCreated = await _openAddCardForBooking();

        if (!mounted || !cardCreated) return;

        setState(() {
          isReserving = false;
        });

        await _reserveExperience(skipReview: true);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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
        isReserving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final experience = widget.experience;
    final galleryPhotos = experience.galleryPhotoUrls;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      bottomNavigationBar: _BottomBookingBar(
        unitPrice: formattedUnitPrice,
        totalPrice: formattedTotal,
        canReserve: canReserve,
        isLoading: isReserving,
        onReserve: _reserveExperience,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _ExperiencePhotoGallery(photos: galleryPhotos),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 14,
                    left: 18,
                    child: _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: _goBackFromDetail,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 14,
                    right: 76,
                    child: _CircleButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isFavorite
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF111827),
                      onTap: _toggleFavorite,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 14,
                    right: 18,
                    child: _CircleButton(
                      icon: Icons.share_rounded,
                      onTap: _openShareModal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: _MainInfoCard(
                experience: experience,
                rating: _currentRating,
                reviewsCount: _currentReviewsCount,
              ),
            ),
          ),
          if (experience.mapPickupPoints.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                child: _PickupPointsCard(
                  pickupPoints: experience.mapPickupPoints,
                  onOpenDirections: _openPickupPointDirections,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: ExperienceReviewsSection(
                experienceId: experience.id,
                averageRating: _currentRating,
                totalReviews: _currentReviewsCount,
                onSummaryChanged: (rating, total) {
                  setState(() {
                    _currentRating = rating;
                    _currentReviewsCount = total;
                  });
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: _BookingCard(
                pickupPoints: experience.includesTransport
                    ? experience.pickupPoints
                    : const [],
                selectedPickupPoint: selectedPickupPoint,
                onPickupPointChanged: (value) {
                  setState(() {
                    selectedPickupPoint = value;
                  });
                },
                availableSchedules: availableSchedules,
                selectedSchedule: selectedSchedule,
                travelersController: _travelersController,
                travelers: travelers,
                maxTravelers: maxTravelers,
                includesMinors: includesMinors,
                minorCount: minorCount,
                onIncludesMinorsChanged: _updateIncludesMinors,
                onMinorCountChanged: _updateMinorCount,
                onScheduleChanged: _onScheduleChanged,
                onMinus: () => _updateTravelers(travelers - 1),
                onPlus: () => _updateTravelers(travelers + 1),
                onTravelersTyped: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed == null) return;
                  _updateTravelers(parsed);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 130),
              child: _ContactProviderCard(
                isOpeningChat: isOpeningChat,
                onContactProvider: _contactProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openShareModal() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Compartir experiencia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ShareOption(
                  icon: Icons.email_outlined,
                  title: 'Compartir por mail',
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchShareUri(
                      Uri(
                        scheme: 'mailto',
                        queryParameters: {
                          'subject': 'Experiencia en AndanDO',
                          'body': shareMessage,
                        },
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.chat_outlined,
                  title: 'Compartir por WhatsApp',
                  onTap: () async {
                    Navigator.pop(context);
                    final encoded = Uri.encodeComponent(shareMessage);
                    await _launchShareUri(
                      Uri.parse('https://wa.me/?text=$encoded'),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.sms_outlined,
                  title: 'Compartir por Apple Message',
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchShareUri(
                      Uri(
                        scheme: 'sms',
                        queryParameters: {'body': shareMessage},
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.link_rounded,
                  title: 'Copiar link',
                  onTap: () async {
                    Navigator.pop(context);
                    await Clipboard.setData(ClipboardData(text: shareLink));

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copiado al portapapeles.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchShareUri(Uri uri) async {
    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir esta opción para compartir.'),
        ),
      );

      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  }

  Future<void> _openPickupPointDirections(
    CustomerExperiencePickupPointModel point,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}',
    );

    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );

      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}

class _MainInfoCard extends StatelessWidget {
  final CustomerExperienceModel experience;
  final double rating;
  final int reviewsCount;

  const _MainInfoCard({
    required this.experience,
    required this.rating,
    required this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = experience.displayAmenities;
    final itinerary = experience.displayItinerary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  experience.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (experience.instantConfirmation)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Instantánea',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  experience.displayLocation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: Color(0xFFFACC15),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${rating.toStringAsFixed(1)} ($reviewsCount reseñas)',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    experience.displayDuration,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              experience.description?.trim().isNotEmpty == true
                  ? experience.description!
                  : 'Vive una experiencia única diseñada para descubrir lo mejor del destino.',
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 18),
          const Text(
            'Incluye:',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: amenities
                .map((item) => _IncludeItem(text: item))
                .toList(),
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 18),
          const Text(
            'Itinerario:',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),
          ...itinerary.map(
            (item) => _ItineraryItem(time: item.time, text: item.activity),
          ),
        ],
      ),
    );
  }
}

class _ContactProviderCard extends StatelessWidget {
  final bool isOpeningChat;
  final VoidCallback onContactProvider;

  const _ContactProviderCard({
    required this.isOpeningChat,
    required this.onContactProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF003B73),
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¿Tienes dudas antes de reservar?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Comunícate con el afiliado para consultar disponibilidad, punto de encuentro, transporte o cualquier detalle de la experiencia.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isOpeningChat ? null : onContactProvider,
              icon: isOpeningChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(
                isOpeningChat ? 'Abriendo chat...' : 'Contactar afiliado',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF003B73),
                side: const BorderSide(color: Color(0xFF003B73)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final List<String> pickupPoints;
  final String? selectedPickupPoint;
  final ValueChanged<String?> onPickupPointChanged;

  final List<CustomerExperienceScheduleModel> availableSchedules;
  final CustomerExperienceScheduleModel? selectedSchedule;
  final TextEditingController travelersController;
  final int travelers;
  final int maxTravelers;
  final bool includesMinors;
  final int minorCount;
  final ValueChanged<bool> onIncludesMinorsChanged;
  final ValueChanged<int> onMinorCountChanged;
  final ValueChanged<CustomerExperienceScheduleModel?> onScheduleChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onTravelersTyped;

  const _BookingCard({
    required this.pickupPoints,
    required this.selectedPickupPoint,
    required this.onPickupPointChanged,
    required this.availableSchedules,
    required this.selectedSchedule,
    required this.travelersController,
    required this.travelers,
    required this.maxTravelers,
    required this.includesMinors,
    required this.minorCount,
    required this.onIncludesMinorsChanged,
    required this.onMinorCountChanged,
    required this.onScheduleChanged,
    required this.onMinus,
    required this.onPlus,
    required this.onTravelersTyped,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedules = availableSchedules.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reserva tu experiencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          if (pickupPoints.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Punto de recogida',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedPickupPoint,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Selecciona dónde te recogerán',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
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
                  borderSide: const BorderSide(color: Color(0xFF003B73)),
                ),
              ),
              items: pickupPoints.map((point) {
                return DropdownMenuItem<String>(
                  value: point,
                  child: Text(point),
                );
              }).toList(),
              onChanged: onPickupPointChanged,
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Fecha disponible',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          if (hasSchedules)
            _ScheduleSelector(
              availableSchedules: availableSchedules,
              selectedSchedule: selectedSchedule,
              onChanged: onScheduleChanged,
            )
          else
            const _NoSchedulesBox(),
          const SizedBox(height: 22),
          const Text(
            'Viajeros',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          _TravelersSelector(
            controller: travelersController,
            travelers: travelers,
            maxTravelers: maxTravelers,
            enabled: hasSchedules && selectedSchedule != null,
            onMinus: onMinus,
            onPlus: onPlus,
            onChanged: onTravelersTyped,
          ),
          const SizedBox(height: 8),
          Text(
            selectedSchedule == null
                ? 'Selecciona una fecha para ver los cupos disponibles.'
                : 'Mínimo 1 adulto. La suma de viajeros adultos y menores no puede superar $maxTravelers cupos.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 14),
          SwitchListTile.adaptive(
            value: includesMinors,
            onChanged: selectedSchedule == null
                ? null
                : onIncludesMinorsChanged,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'La reserva incluye menores de edad',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            subtitle: const Text(
              'Los menores se agregarán a la cantidad de viajeros seleccionada y ocuparán cupos adicionales.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF64748B),
              ),
            ),
            activeThumbColor: const Color(0xFF003B73),
          ),
          if (includesMinors) ...[
            const SizedBox(height: 14),
            const Text(
              'Cantidad de menores',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            _MinorCountSelector(
              minorCount: minorCount,
              maxMinorCount: maxTravelers - travelers,
              onMinus: () {
                onMinorCountChanged(minorCount - 1);
              },
              onPlus: () {
                onMinorCountChanged(minorCount + 1);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes agregar hasta ${maxTravelers - travelers} menor(es). '
              'Total actual: ${travelers + minorCount} participante(s).',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleSelector extends StatefulWidget {
  final List<CustomerExperienceScheduleModel> availableSchedules;
  final CustomerExperienceScheduleModel? selectedSchedule;
  final ValueChanged<CustomerExperienceScheduleModel?> onChanged;

  const _ScheduleSelector({
    required this.availableSchedules,
    required this.selectedSchedule,
    required this.onChanged,
  });

  @override
  State<_ScheduleSelector> createState() => _ScheduleSelectorState();
}

class _ScheduleSelectorState extends State<_ScheduleSelector> {
  final GlobalKey _fieldKey = GlobalKey();

  Future<void> _openMenu() async {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final fieldOffset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    final fieldSize = renderBox.size;

    final selected = await showMenu<CustomerExperienceScheduleModel>(
      context: context,
      color: Colors.white,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
        maxHeight: 280,
      ),
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldSize.height + 6,
        overlay.size.width - fieldOffset.dx - fieldSize.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      items: widget.availableSchedules.map((schedule) {
        return PopupMenuItem<CustomerExperienceScheduleModel>(
          value: schedule,
          height: 58,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  schedule.formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                schedule.availableSpots == 1
                    ? '1 cupo disponible'
                    : '${schedule.availableSpots} cupos disponibles',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedSchedule = widget.selectedSchedule != null;

    return InkWell(
      key: _fieldKey,
      onTap: _openMenu,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSelectedSchedule
                    ? '${widget.selectedSchedule!.formattedDate} · ${widget.selectedSchedule!.availableSpots} cupos'
                    : 'Selecciona una fecha',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasSelectedSchedule
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: hasSelectedSchedule
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSchedulesBox extends StatelessWidget {
  const _NoSchedulesBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Text(
        'Esta experiencia todavía no tiene fechas disponibles para reservar.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9A3412),
        ),
      ),
    );
  }
}

class _TravelersSelector extends StatelessWidget {
  final TextEditingController controller;
  final int travelers;
  final int maxTravelers;
  final bool enabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onChanged;

  const _TravelersSelector({
    required this.controller,
    required this.travelers,
    required this.maxTravelers,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _CounterButton(
            icon: Icons.remove_rounded,
            enabled: enabled && travelers > 1,
            onTap: onMinus,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '1',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            enabled: enabled && travelers < maxTravelers,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _MinorCountSelector extends StatelessWidget {
  final int minorCount;
  final int maxMinorCount;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _MinorCountSelector({
    required this.minorCount,
    required this.maxMinorCount,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _CounterButton(
            icon: Icons.remove_rounded,
            enabled: minorCount > 1,
            onTap: onMinus,
          ),
          Expanded(
            child: Text(
              minorCount.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            enabled: minorCount < maxMinorCount,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF111827) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _BottomBookingBar extends StatelessWidget {
  final String unitPrice;
  final String totalPrice;
  final bool canReserve;
  final bool isLoading;
  final VoidCallback onReserve;

  const _BottomBookingBar({
    required this.unitPrice,
    required this.totalPrice,
    required this.canReserve,
    required this.isLoading,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = canReserve
        ? const Color(0xFF003B73)
        : const Color(0xFFCBD5E1);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unitPrice por persona',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003B73),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              height: 56,
              child: ElevatedButton(
                onPressed: canReserve ? onReserve : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Reservar ahora',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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

class _PickupPointsCard extends StatelessWidget {
  final List<CustomerExperiencePickupPointModel> pickupPoints;
  final ValueChanged<CustomerExperiencePickupPointModel> onOpenDirections;

  const _PickupPointsCard({
    required this.pickupPoints,
    required this.onOpenDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Color(0xFF003B73),
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Puntos de recogida',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'El afiliado ha indicado estos puntos para iniciar la experiencia.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          ...pickupPoints.map(
            (point) => _PickupPointItem(
              point: point,
              onOpenDirections: () => onOpenDirections(point),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupPointItem extends StatelessWidget {
  final CustomerExperiencePickupPointModel point;
  final VoidCallback onOpenDirections;

  const _PickupPointItem({required this.point, required this.onOpenDirections});

  @override
  Widget build(BuildContext context) {
    final instructions = point.displayInstructions;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: Color(0xFF003B73),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.displayAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (instructions != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instructions,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onOpenDirections,
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Cómo llegar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF003B73),
                side: const BorderSide(color: Color(0xFF003B73)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF111827)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
      ),
      onTap: onTap,
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}

class _IncludeItem extends StatelessWidget {
  final String text;

  const _IncludeItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryItem extends StatelessWidget {
  final String time;
  final String text;

  const _ItineraryItem({required this.time, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF003B73),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperiencePhotoGallery extends StatefulWidget {
  final List<String> photos;

  const _ExperiencePhotoGallery({required this.photos});

  @override
  State<_ExperiencePhotoGallery> createState() =>
      _ExperiencePhotoGalleryState();
}

class _ExperiencePhotoGalleryState extends State<_ExperiencePhotoGallery> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPhotoViewer(int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: widget.photos.length,
                itemBuilder: (_, index) {
                  return InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        widget.photos[index],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const _DetailImagePlaceholder(),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: _CircleButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const _DetailImagePlaceholder();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (_, index) {
            return GestureDetector(
              onTap: () => _openPhotoViewer(index),
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _DetailImagePlaceholder(),
              ),
            );
          },
        ),

        if (widget.photos.length > 1)
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.photos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),

        if (widget.photos.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (index) {
                final isActive = index == _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isActive ? 0.95 : 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9D2D8),
      child: const Center(
        child: Icon(
          Icons.location_on_outlined,
          size: 92,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _BookingReviewDialog extends StatefulWidget {
  final String experienceTitle;
  final String date;
  final int travelers;
  final bool includesMinors;
  final int minorCount;
  final String duration;
  final String unitPrice;
  final String totalPrice;
  final List<String> includedItems;
  final String? cancellationPolicy;
  final LegalDocument paymentPolicyDocument;
  final LegalDocument waiverDocument;
  final LegalDocument? minorsDocument;

  const _BookingReviewDialog({
    required this.experienceTitle,
    required this.date,
    required this.travelers,
    required this.includesMinors,
    required this.minorCount,
    required this.duration,
    required this.unitPrice,
    required this.totalPrice,
    required this.includedItems,
    required this.cancellationPolicy,
    required this.paymentPolicyDocument,
    required this.waiverDocument,
    required this.minorsDocument,
  });

  @override
  State<_BookingReviewDialog> createState() => _BookingReviewDialogState();
}

class _BookingReviewDialogState extends State<_BookingReviewDialog> {
  bool acceptedBookingLegalDocuments = false;

  void _openInfoModal({required String title, required String content}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(height: 1.45, color: Color(0xFF475569)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Revisar reserva',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Resumen de tu reserva',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Experiencia',
                      value: widget.experienceTitle,
                    ),
                    _SummaryRow(label: 'Fecha', value: widget.date),
                    _SummaryRow(
                      label: 'Participantes',
                      value: widget.travelers == 1
                          ? '1 persona'
                          : '${widget.travelers} personas',
                    ),
                    if (widget.includesMinors)
                      _SummaryRow(
                        label: 'Menores incluidos',
                        value: widget.minorCount == 1
                            ? '1 menor'
                            : '${widget.minorCount} menores',
                      ),
                    if (widget.includesMinors)
                      _SummaryRow(
                        label: 'Adultos',
                        value: (widget.travelers - widget.minorCount) == 1
                            ? '1 adulto'
                            : '${widget.travelers - widget.minorCount} adultos',
                      ),
                    _SummaryRow(label: 'Duración', value: widget.duration),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Desglose de precios',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              _PriceRow(
                label: '${widget.unitPrice} x ${widget.travelers} viajero(s)',
                value: widget.totalPrice,
              ),
              const Divider(height: 28),
              _PriceRow(
                label: 'Total',
                value: widget.totalPrice,
                isTotal: true,
              ),
              const SizedBox(height: 26),
              const Text(
                'Políticas importantes',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              _CancellationPolicyCard(policy: widget.cancellationPolicy),
              const SizedBox(height: 15),
              const _PolicyItem(
                icon: Icons.credit_card_rounded,
                iconColor: Color(0xFF003B73),
                title: 'Condiciones de cobro',
                text:
                    'Para reservar necesitas una tarjeta registrada. El cobro se realizará automáticamente 24 horas después de creada la reserva. Si la reserva se realiza dentro del período no reembolsable definido por el proveedor, las condiciones de cancelación aplican desde el momento de la reserva.',
              ),
              _PolicyItem(
                icon: Icons.check_rounded,
                iconColor: const Color(0xFF003B73),
                title: 'Qué incluye',
                text: widget.includedItems.join(', '),
              ),

              const SizedBox(height: 18),

              CheckboxListTile(
                value: acceptedBookingLegalDocuments,
                onChanged: (value) {
                  setState(() {
                    acceptedBookingLegalDocuments = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Certifico que he leído y acepto:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      InkWell(
                        onTap: () => _openInfoModal(
                          title: widget.paymentPolicyDocument.title,
                          content: widget.paymentPolicyDocument.content,
                        ),
                        child: Text(
                          widget.paymentPolicyDocument.title,
                          style: const TextStyle(
                            color: Color(0xFF003B73),
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        '·',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      InkWell(
                        onTap: () => _openInfoModal(
                          title: widget.waiverDocument.title,
                          content: widget.waiverDocument.content,
                        ),
                        child: Text(
                          widget.waiverDocument.title,
                          style: const TextStyle(
                            color: Color(0xFF003B73),
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (widget.includesMinors &&
                          widget.minorsDocument != null) ...[
                        const Text(
                          '·',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        InkWell(
                          onTap: () => _openInfoModal(
                            title: widget.minorsDocument!.title,
                            content: widget.minorsDocument!.content,
                          ),
                          child: Text(
                            widget.minorsDocument!.title,
                            style: const TextStyle(
                              color: Color(0xFF003B73),
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: acceptedBookingLegalDocuments
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B73),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Confirmar reserva',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Revisar Reserva',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCancellationPolicy(String? policy) {
  final normalized = policy?.trim();

  switch (normalized) {
    case 'free_24h':
      return 'El proveedor permite cancelación gratuita hasta 24 horas antes del inicio. Si cancelas dentro de las últimas 24 horas, la reserva no será reembolsable. Si cancelas fuera de ese período, pero el cobro ya fue realizado, AndanDO retendrá un 5% administrativo y reembolsará el 95%.';

    case 'free_48h':
      return 'El proveedor permite cancelación gratuita hasta 48 horas antes del inicio. Si cancelas dentro de las últimas 48 horas, la reserva no será reembolsable. Si cancelas fuera de ese período, pero el cobro ya fue realizado, AndanDO retendrá un 5% administrativo y reembolsará el 95%.';

    case 'free_72h':
      return 'El proveedor permite cancelación gratuita hasta 72 horas antes del inicio. Si cancelas dentro de las últimas 72 horas, la reserva no será reembolsable. Si cancelas fuera de ese período, pero el cobro ya fue realizado, AndanDO retendrá un 5% administrativo y reembolsará el 95%.';

    case 'free_5d':
      return 'El proveedor permite cancelación gratuita hasta 5 días antes del inicio. Si cancelas dentro de los últimos 5 días, la reserva no será reembolsable. Si cancelas fuera de ese período, pero el cobro ya fue realizado, AndanDO retendrá un 5% administrativo y reembolsará el 95%.';

    case 'no_refund':
      return 'Esta experiencia es no reembolsable según la política del proveedor. Una vez creada la reserva, no aplica reembolso, salvo cancelación atribuible al proveedor o decisión administrativa de AndanDO.';

    default:
      return normalized != null && normalized.isNotEmpty
          ? normalized
          : 'Cancelación sujeta a la política del proveedor. Si cancelas fuera del período no reembolsable, pero el cobro ya fue realizado, AndanDO retendrá un 5% administrativo y reembolsará el 95%.';
  }
}

class _CancellationPolicyCard extends StatelessWidget {
  final String? policy;

  const _CancellationPolicyCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    final normalized = policy?.trim();

    String title;
    String freeWindow;
    String penaltyWindow;

    switch (normalized) {
      case 'free_24h':
        title = 'Política de esta experiencia';
        freeWindow = 'Cancelación gratuita hasta 24 horas antes.';
        penaltyWindow = 'Dentro de las últimas 24 horas no aplica reembolso.';
        break;

      case 'free_48h':
        title = 'Política de esta experiencia';
        freeWindow = 'Cancelación gratuita hasta 48 horas antes.';
        penaltyWindow = 'Dentro de las últimas 48 horas no aplica reembolso.';
        break;

      case 'free_72h':
        title = 'Política de esta experiencia';
        freeWindow = 'Cancelación gratuita hasta 72 horas antes.';
        penaltyWindow = 'Dentro de las últimas 72 horas no aplica reembolso.';
        break;

      case 'free_5d':
        title = 'Política de esta experiencia';
        freeWindow = 'Cancelación gratuita hasta 5 días antes.';
        penaltyWindow = 'Dentro de los últimos 5 días no aplica reembolso.';
        break;

      case 'no_refund':
        title = 'Política de esta experiencia';
        freeWindow = 'Esta experiencia es no reembolsable.';
        penaltyWindow = 'No aplica devolución después de creada la reserva.';
        break;

      default:
        title = 'Política de esta experiencia';
        freeWindow = 'Aplican condiciones de cancelación.';
        penaltyWindow = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gpp_good_rounded, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text(
                'Política de esta experiencia',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            freeWindow,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            penaltyWindow,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Luego de 24 horas de realizada la reserva, se procesará el cobro de la experiencia.\n\n'
            'Si cancelas antes de entrar en el período no reembolsable, AndanDO reembolsará el 95% del monto pagado y retendrá un 5% por costos administrativos.\n\n'
            'Si cancelas dentro del período no reembolsable de esta experiencia, no aplicará reembolso.',
            style: TextStyle(
              height: 1.4,
              fontSize: 13,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingSuccessDialog extends StatelessWidget {
  final String bookingCode;
  final String totalPrice;

  const _BookingSuccessDialog({
    required this.bookingCode,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 42,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Reserva creada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu reserva fue creada correctamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Código de reserva',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    bookingCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003B73),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total pagado',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Text(
                        totalPrice,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF003B73),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Ver mi reserva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B73),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Seguir explorando',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
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

class _BookingCodeBox extends StatelessWidget {
  final String bookingCode;

  const _BookingCodeBox({required this.bookingCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Color(0xFF003B73),
              ),
              SizedBox(width: 8),
              Text(
                'Código de reserva',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            bookingCode,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF003B73),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guarda este código para futuras consultas.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 21 : 15,
            fontWeight: FontWeight.w900,
            color: isTotal ? const Color(0xFF003B73) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String text;

  const _PolicyItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF64748B),
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
