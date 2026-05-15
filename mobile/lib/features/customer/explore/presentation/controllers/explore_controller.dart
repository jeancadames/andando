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
/// - estados de loading y error
class ExploreController extends ChangeNotifier {
  final ExploreRemoteDataSource _dataSource;

  ExploreController({
    ExploreRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? ExploreRemoteDataSource();

  /// Lista de experiencias visibles en pantalla.
  List<CustomerExperienceModel> experiences = [];

  /// Categorías disponibles para los chips superiores.
  List<String> categories = ['Todos'];

  /// Categoría seleccionada actualmente.
  String selectedCategory = 'Todos';

  /// Texto actual del buscador.
  String searchText = '';

  /// Indica si la pantalla está cargando datos.
  bool isLoading = false;

  /// Mensaje de error, si ocurre uno.
  String? errorMessage;

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
    selectedCategory = category;
    await loadExperiences();
  }

  /// Actualiza el texto de búsqueda.
  Future<void> search(String value) async {
    searchText = value;
    await loadExperiences();
  }

  /// Limpia filtros y vuelve a cargar.
  Future<void> clearFilters() async {
    searchText = '';
    selectedCategory = 'Todos';
    await loadExperiences();
  }
}