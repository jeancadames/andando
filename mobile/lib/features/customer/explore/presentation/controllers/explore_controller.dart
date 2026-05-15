import 'package:flutter/material.dart';

import '../../data/datasources/explore_remote_datasource.dart';
import '../../data/models/customer_experience_model.dart';

/// Controlador de estado para la pantalla Explorar.
///
/// Administra:
/// - carga inicial de experiencias
/// - categorías
/// - búsqueda
/// - filtro por categoría
/// - favoritos temporales
/// - carruseles de experiencias
/// - estados de loading y error
class ExploreController extends ChangeNotifier {
  final ExploreRemoteDataSource _dataSource;

  ExploreController({
    ExploreRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? ExploreRemoteDataSource();

  /// Lista general de experiencias visibles en pantalla.
  List<CustomerExperienceModel> experiences = [];

  /// Categorías disponibles para los chips superiores.
  List<String> categories = ['Todos'];

  /// IDs de experiencias marcadas como favoritas.
  ///
  /// Por ahora se guardan en memoria para que funcione tanto
  /// para usuarios autenticados como para visitantes.
  final Set<int> favoriteExperienceIds = {};

  /// Categoría seleccionada actualmente.
  String selectedCategory = 'Todos';

  /// Texto actual del buscador.
  String searchText = '';

  /// Indica si la pantalla está cargando datos.
  bool isLoading = false;

  /// Mensaje de error, si ocurre uno.
  String? errorMessage;

  /// Experiencias populares.
  ///
  /// Por ahora usa todas las experiencias cargadas.
  List<CustomerExperienceModel> get popularExperiences {
    return experiences;
  }

  /// Experiencias recomendadas según favoritos.
  ///
  /// Si el usuario ha dado like a experiencias, se recomiendan otras
  /// experiencias de las mismas categorías.
  ///
  /// Si todavía no hay favoritos, muestra experiencias generales.
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

  /// Experiencias cercanas al usuario.
  ///
  /// Más adelante esto debe calcularse con ubicación real del dispositivo.
  /// Por ahora prioriza experiencias que tengan ubicación o provincia.
  List<CustomerExperienceModel> get nearbyExperiences {
    final nearby = experiences.where((experience) {
      return (experience.location != null &&
              experience.location!.trim().isNotEmpty) ||
          (experience.province != null && experience.province!.trim().isNotEmpty);
    }).toList();

    return nearby.isEmpty ? experiences : nearby;
  }

  /// Carga inicial de datos.
  Future<void> initialize() async {
    await Future.wait([
      loadCategories(),
      loadExperiences(),
    ]);
  }

  /// Carga las experiencias desde el backend.
  Future<void> loadExperiences() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      experiences = await _dataSource.getExperiences(
        search: searchText,
        category: selectedCategory,
      );
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las categorías disponibles.
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

  /// Cambia la categoría seleccionada y recarga experiencias.
  Future<void> selectCategory(String category) async {
    if (selectedCategory == category) return;

    selectedCategory = category;
    await loadExperiences();
  }

  /// Actualiza el texto de búsqueda.
  Future<void> search(String value) async {
    searchText = value;
    await loadExperiences();
  }

  /// Verifica si una experiencia está marcada como favorita.
  bool isFavorite(int experienceId) {
    return favoriteExperienceIds.contains(experienceId);
  }

  /// Alterna favorito/no favorito.
  void toggleFavorite(int experienceId) {
    if (favoriteExperienceIds.contains(experienceId)) {
      favoriteExperienceIds.remove(experienceId);
    } else {
      favoriteExperienceIds.add(experienceId);
    }

    notifyListeners();
  }

  /// Limpia filtros y vuelve a cargar.
  Future<void> clearFilters() async {
    searchText = '';
    selectedCategory = 'Todos';
    await loadExperiences();
  }
}