import 'package:flutter/material.dart';

import '../../data/datasources/explore_remote_datasource.dart';
import '../../data/models/customer_experience_model.dart';

class ExploreController extends ChangeNotifier {
  final ExploreRemoteDataSource _dataSource;
  ExploreRemoteDataSource get dataSource => _dataSource;

  ExploreController({
    ExploreRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? ExploreRemoteDataSource();

  List<CustomerExperienceModel> experiences = [];

  List<String> categories = ['Todos'];

  Set<int> favoriteExperienceIds = {};

  String selectedCategory = 'Todos';

  String searchText = '';

  bool isLoading = false;

  String? errorMessage;

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
    final nearby = experiences.where((experience) {
      return (experience.location != null &&
              experience.location!.trim().isNotEmpty) ||
          (experience.province != null &&
              experience.province!.trim().isNotEmpty);
    }).toList();

    return nearby.isEmpty ? experiences : nearby;
  }

  Future<void> initialize() async {
    await Future.wait([
      loadCategories(),
      loadExperiences(),
    ]);
  }

  Future<void> loadExperiences() async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      experiences = await _dataSource.getExperiences(
        search: searchText,
        category: selectedCategory,
      );

      favoriteExperienceIds = experiences
          .where((experience) => experience.isFavorite)
          .map((experience) => experience.id)
          .toSet();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

    await loadExperiences();
  }

  Future<void> search(String value) async {
    searchText = value;

    await loadExperiences();
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

    await loadExperiences();
  }
}