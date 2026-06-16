import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import '../../data/datasources/explore_remote_datasource.dart';
import '../../data/models/customer_experience_model.dart';
import '../../../profile/data/services/customer_location_preferences_service.dart';

class ExploreController extends ChangeNotifier {
  final ExploreRemoteDataSource _dataSource;

  final CustomerLocationPreferencesService _locationPreferencesService =
    CustomerLocationPreferencesService();

    int searchRadiusKm = 50;
    bool gpsEnabled = true;
    bool autoDetectLocation = false;

  ExploreRemoteDataSource get dataSource => _dataSource;

  ExploreController({
    ExploreRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? ExploreRemoteDataSource();

  List<CustomerExperienceModel> experiences = [];
  List<CustomerExperienceModel> nearbyExperiencesList = [];

  List<String> categories = ['Todos'];

  Set<int> favoriteExperienceIds = {};

  String selectedCategory = 'Todos';

  String searchText = '';

  /// Fecha seleccionada para filtrar experiencias.
  ///
  /// Si es null, se muestran todas las fechas.
  DateTime? selectedDate;

  bool isLoading = false;

  String? errorMessage;
  double? userLatitude;
  double? userLongitude;
  bool locationPermissionDenied = false;
  bool hasLoadedOnce = false;

  List<CustomerExperienceModel> get popularExperiences {
    return experiences;
  }

  List<CustomerExperienceModel> get recommendedExperiences {
    if (favoriteExperienceIds.isEmpty) {
      return experiences;
    }

    final favoriteCategories = experiences
        .where((experience) => favoriteExperienceIds.contains(experience.id))
        .map((experience) => experience.category)
        .whereType<String>()
        .toSet();

    final recommended = experiences.where((experience) {
      return favoriteCategories.contains(experience.category) &&
          !favoriteExperienceIds.contains(experience.id);
    }).toList();

    return recommended.isEmpty ? experiences : recommended;
  }

  List<CustomerExperienceModel> get nearbyExperiences {
    return nearbyExperiencesList;
  }

  Future<void> initialize() async {
    await _loadLocationPreferences();

    if (gpsEnabled || autoDetectLocation) {
      await _loadUserLocation();
    }

    await Future.wait([
      loadCategories(),
      loadExperiences(),
      loadNearbyExperiences(),
    ]);
  }

  Future<void> _loadLocationPreferences() async {
    gpsEnabled = await _locationPreferencesService.getGpsEnabled();
    autoDetectLocation =
        await _locationPreferencesService.getAutoDetectEnabled();
    searchRadiusKm = await _locationPreferencesService.getSearchRadiusKm();
  }

  Future<void> loadExperiences() async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      experiences = await _dataSource.getExperiences(
        search: searchText,
        category: selectedCategory,
        selectedDate: selectedDate,
      );

      favoriteExperienceIds = experiences
          .where((experience) => experience.isFavorite)
          .map((experience) => experience.id)
          .toSet();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      hasLoadedOnce = true;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerExperienceModel> getExperienceDetail(int experienceId) async {
    final experience = await _dataSource.getExperienceDetail(
      experienceId: experienceId,
    );

    if (experience.isFavorite) {
      favoriteExperienceIds.add(experience.id);
    } else {
      favoriteExperienceIds.remove(experience.id);
    }

    return experience;
  }

  Future<void> loadCategories() async {
    try {
      categories = await _dataSource.getCategories();

      if (!categories.contains('Todos')) {
        categories.insert(0, 'Todos');
      }
    } catch (_) {
      categories = ['Todos'];
    }

    notifyListeners();
  }

  Future<void> selectCategory(String category) async {
    if (selectedCategory == category) return;

    selectedCategory = category;

    await Future.wait([
      loadExperiences(),
      loadNearbyExperiences(),
    ]);
  }

  Future<void> _loadUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        locationPermissionDenied = true;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationPermissionDenied = true;
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      userLatitude = position.latitude;
      userLongitude = position.longitude;
      locationPermissionDenied = false;
    } catch (_) {
      locationPermissionDenied = true;
    }
  }

  Future<void> loadNearbyExperiences() async {
    if (userLatitude == null || userLongitude == null) {
      nearbyExperiencesList = [];
      notifyListeners();
      return;
    }

    try {
      nearbyExperiencesList = await _dataSource.getExperiences(
        search: searchText,
        category: selectedCategory,
        selectedDate: selectedDate,
        latitude: userLatitude,
        longitude: userLongitude,
        radiusKm: searchRadiusKm,
      );

      nearbyExperiencesList = nearbyExperiencesList
          .where((experience) => experience.distanceKm != null)
          .toList();

      nearbyExperiencesList.sort(
        (a, b) => a.distanceKm!.compareTo(b.distanceKm!),
      );
    } catch (_) {
      nearbyExperiencesList = [];
    }

    notifyListeners();
  }

  Future<void> search(String value) async {
    searchText = value;

    await Future.wait([
      loadExperiences(),
      loadNearbyExperiences(),
    ]);
  }

  /// Selecciona una fecha y recarga experiencias filtradas.
  Future<void> selectDate(DateTime date) async {
    selectedDate = date;
    await Future.wait([
      loadExperiences(),
      loadNearbyExperiences(),
    ]);
  }

  /// Limpia la fecha seleccionada.
  Future<void> clearSelectedDate() async {
    selectedDate = null;
    await Future.wait([
      loadExperiences(),
      loadNearbyExperiences(),
    ]);
  }

  bool isFavorite(int experienceId) {
    return favoriteExperienceIds.contains(experienceId);
  }

  Future<void> toggleFavorite(int experienceId) async {
    final wasFavorite = favoriteExperienceIds.contains(experienceId);

    if (wasFavorite) {
      favoriteExperienceIds.remove(experienceId);
    } else {
      favoriteExperienceIds.add(experienceId);
    }

    notifyListeners();

    try {
      if (wasFavorite) {
        await _dataSource.removeFavorite(
          experienceId: experienceId,
        );
      } else {
        await _dataSource.addFavorite(
          experienceId: experienceId,
        );
      }
    } catch (error) {
      if (wasFavorite) {
        favoriteExperienceIds.add(experienceId);
      } else {
        favoriteExperienceIds.remove(experienceId);
      }

      errorMessage = error.toString();

      notifyListeners();
    }
  }

  Future<void> clearFilters() async {
    searchText = '';
    selectedCategory = 'Todos';
    selectedDate = null;

    await Future.wait([
      loadExperiences(),
      loadNearbyExperiences(),
    ]);
  }
}