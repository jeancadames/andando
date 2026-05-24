import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../auth/application/auth_controller.dart';
import '../../data/datasources/customer_profile_remote_datasource.dart';
import '../../data/models/customer_profile_model.dart';

/// Controlador de estado para el perfil del cliente.
///
/// Administra:
/// - carga del perfil.
/// - actualización de datos personales.
/// - actualización de foto de perfil.
/// - cierre de sesión local y remoto.
class CustomerProfileController extends ChangeNotifier {
  CustomerProfileController({
    AuthController? authController,
    CustomerProfileRemoteDataSource? dataSource,
  })  : _authController = authController,
        _dataSource = dataSource ?? CustomerProfileRemoteDataSource();

  final AuthController? _authController;
  final CustomerProfileRemoteDataSource _dataSource;

  bool isLoading = false;
  bool isSaving = false;
  bool isUploadingPhoto = false;
  bool isLoggingOut = false;

  String? errorMessage;

  CustomerProfileModel? profile;

  CustomerProfileUser? get user => profile?.user;
  CustomerProfileStats? get stats => profile?.stats;
  CustomerNextBooking? get nextBooking => profile?.nextBooking;

  /// Carga el perfil desde backend.
  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _dataSource.getProfile();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza los datos personales del cliente.
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? birthDate,
    String? gender,
    String? nationality,
    String? residenceCity,
    String? preferredCurrency,
    String? language,
    String? country,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _dataSource.updateProfile(
        name: name,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        nationality: nationality,
        residenceCity: residenceCity,
        preferredCurrency: preferredCurrency,
        language: language,
        country: country,
      );

      _replaceUser(updatedUser);

      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Actualiza la foto de perfil.
  Future<bool> updateProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    isUploadingPhoto = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _dataSource.updateProfilePhoto(
        bytes: bytes,
        fileName: fileName,
      );

      _replaceUser(updatedUser);

      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isUploadingPhoto = false;
      notifyListeners();
    }
  }

  /// Cierra sesión en backend y luego limpia la sesión global local.
  Future<bool> logout() async {
    isLoggingOut = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.logout();
      await _authController?.logout();
      return true;
    } catch (_) {
      await _authController?.logout();
      return true;
    } finally {
      isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Reemplaza el usuario dentro del perfil sin perder stats ni próxima reserva.
  void _replaceUser(CustomerProfileUser updatedUser) {
    if (profile == null) return;

    profile = CustomerProfileModel(
      user: updatedUser,
      stats: profile!.stats,
      nextBooking: profile!.nextBooking,
    );
  }

  /// Limpia errores visibles en UI.
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}