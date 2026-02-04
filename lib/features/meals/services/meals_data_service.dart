import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/secure_delete_service.dart';

/// Service for managing meal data persistence using Hive.
///
/// Handles initialization of encrypted boxes, CRUD operations,
/// and secure deletion with multi-pass overwriting.
class MealsDataService {
  static const String _boxName = 'meals';

  /// Secure delete service for multi-pass sensitive data removal
  final SecureDeleteService _secureDeleteService = SecureDeleteService();

  Future<void> init() async {
    // Migrate to encryption if needed
    await DatabaseService.migrateBoxToEncryption<Meal>(_boxName);

    final cipher = await DatabaseService.getEncryptionCipher();
    await Hive.openLazyBox<Meal>(_boxName, encryptionCipher: cipher);
  }

  LazyBox<Meal> get _box => Hive.lazyBox<Meal>(_boxName);

  Future<List<Meal>> getAllMeals() async {
    final List<Meal> meals = [];
    for (var key in _box.keys) {
      final meal = await _box.get(key);
      if (meal != null) meals.add(meal);
    }
    return meals;
  }

  Future<void> saveMeal(Meal meal) async {
    await _box.put(meal.id, meal);
  }

  Future<void> deleteMeal(String id) async {
    final meal = await _box.get(id);
    if (meal == null) return;

    await _secureDeleteService.multiPassOverwrite(() async {
      // Overwrite with random data
      final randomMeal = Meal(
        id: meal.id,
        title: _secureDeleteService.secureOverwriteString(meal.title),
        description:
            _secureDeleteService.secureOverwriteString(meal.description),
        isFavorite: false,
        imagePath: null,
        category: 'Other',
        rating: 0,
      );
      await _box.put(id, randomMeal);
    });

    await _box.delete(id);
    _secureDeleteService.logSecureDeletion('Meal', id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
