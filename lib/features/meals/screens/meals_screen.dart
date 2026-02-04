import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../models/meal.dart';
import '../widgets/meal_tile.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../core/services/image_compression_service.dart';
import '../services/meals_data_service.dart';

/// Main screen for tracking and managing meals.
///
/// Features:
/// - Categorized filtering (Breakfast, Lunch, Dinner, Snack)
/// - Search by title or description
/// - Infinite scroll pagination
/// - Image picking and automatic compression
/// - Persistent storage via Hive
class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final MealsDataService _dataService = MealsDataService();
  final List<Meal> _allMeals = [];

  List<Meal> _filteredMeals = [];
  List<Meal> _displayedMeals = []; // Paginated subset
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack'
  ];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreData = true;

  // Image compression service
  final ImageCompressionService _imageCompressionService =
      ImageCompressionService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMeals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreMeals();
      }
    }
  }

  Future<void> _loadMeals() async {
    try {
      await _dataService.init();
      final meals = await _dataService.getAllMeals();

      // Simulate network delay to show skeleton
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _allMeals.clear();
          _allMeals.addAll(meals);
          _filterMeals();
          _loadPage();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading meals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load meals: $e')),
        );
      }
    }
  }

  void _loadPage() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= _filteredMeals.length) {
      setState(() => _hasMoreData = false);
      return;
    }

    setState(() {
      _displayedMeals.addAll(
        _filteredMeals.sublist(
          startIndex,
          endIndex > _filteredMeals.length ? _filteredMeals.length : endIndex,
        ),
      );
      _hasMoreData = endIndex < _filteredMeals.length;
    });
  }

  Future<void> _loadMoreMeals() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    _loadPage();

    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _filterMeals() {
    setState(() {
      _filteredMeals = _allMeals.where((m) {
        final matchesCategory =
            _selectedCategory == 'All' || m.category == _selectedCategory;
        final matchesSearch = m.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            m.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();

      // Reset pagination
      _currentPage = 0;
      _displayedMeals = [];
      _hasMoreData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Meals',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showMealForm(context),
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Mascot Skeleton
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader.square(size: 120),
                      const SizedBox(width: 16),
                      Expanded(child: SkeletonLoader.text(height: 100)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search & Filters Skeleton
                  SkeletonLoader.text(
                      height: 50, borderRadius: BorderRadius.circular(12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonLoader.text(
                          width: 60,
                          height: 32,
                          borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: 8),
                      SkeletonLoader.text(
                          width: 60,
                          height: 32,
                          borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: 8),
                      SkeletonLoader.text(
                          width: 60,
                          height: 32,
                          borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: 8),
                      SkeletonLoader.text(
                          width: 60,
                          height: 32,
                          borderRadius: BorderRadius.circular(20)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // List Skeleton
                  const SkeletonCard(),
                  const SkeletonCard(),
                  const SkeletonCard(),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/eat.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: MessageBubble(
                              message: 'Mmmmm...yummy',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterMeals();
                          _loadPage(); // Load first page after filter
                        },
                        decoration: InputDecoration(
                          hintText: 'Search meals...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Category Filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                    _filterMeals();
                                    _loadPage(); // Load first page after filter
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                checkmarkColor:
                                    Theme.of(context).colorScheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _displayedMeals.isEmpty
                      ? const EmptyStateWidget(
                          message: 'No meals found. Time to eat?',
                          icon: Icons.restaurant_outlined,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount:
                              _displayedMeals.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the end
                            if (index == _displayedMeals.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final meal = _displayedMeals[index];
                            return Dismissible(
                              key: ValueKey(meal.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    color: Colors.red.shade300,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              onDismissed: (direction) async {
                                final deletedMeal = meal;
                                setState(() {
                                  _allMeals.remove(meal);
                                  _filterMeals();
                                  _loadPage();
                                });
                                await _dataService.deleteMeal(meal.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    content: const Text('Meal deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        setState(() {
                                          _allMeals.add(deletedMeal);
                                          _filterMeals();
                                          _loadPage();
                                        });
                                        await _dataService
                                            .saveMeal(deletedMeal);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: MealTile(
                                meal: meal,
                                onEdit: () =>
                                    _showMealForm(context, mealToEdit: meal),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showMealForm(BuildContext context, {Meal? mealToEdit}) {
    final titleController =
        TextEditingController(text: mealToEdit?.title ?? '');
    final descController =
        TextEditingController(text: mealToEdit?.description ?? '');
    String selectedCategory =
        mealToEdit?.category ?? _categories.firstWhere((c) => c != 'All');
    double rating = (mealToEdit?.rating ?? 3).toDouble();

    String? selectedImagePath = mealToEdit?.imagePath;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      mealToEdit == null ? 'Log Meal' : 'Edit Meal',
                      style: AppTypography.displayTextTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Image Picker Section
                    GestureDetector(
                      onTap: () async {
                        final source = await showDialog<ImageSource>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Choose Photo Source'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Camera'),
                                  onTap: () =>
                                      Navigator.pop(ctx, ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () =>
                                      Navigator.pop(ctx, ImageSource.gallery),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (source != null) {
                          final XFile? image =
                              await picker.pickImage(source: source);
                          if (image != null) {
                            // Show loading indicator
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Compressing image...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }

                            // Compress the image
                            final compressedPath =
                                await _imageCompressionService.compressImage(
                              File(image.path),
                              quality: ImageCompressionService.qualityMedium,
                            );

                            setModalState(() {
                              selectedImagePath = compressedPath;
                            });
                          }
                        }
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          image: selectedImagePath != null
                              ? DecorationImage(
                                  image:
                                      selectedImagePath!.startsWith('assets/')
                                          ? AssetImage(selectedImagePath!)
                                              as ImageProvider
                                          : FileImage(File(selectedImagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedImagePath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      color: Colors.grey[400], size: 30),
                                  const SizedBox(height: 4),
                                  Text('Add Photo',
                                      style:
                                          TextStyle(color: Colors.grey[500])),
                                ],
                              )
                            : Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  onPressed: () {
                                    setModalState(() {
                                      selectedImagePath = null;
                                    });
                                  },
                                  icon: const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 12,
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.red),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    const Text('Category:'),
                    Wrap(
                      spacing: 8,
                      children:
                          _categories.where((c) => c != 'All').map((category) {
                        return ChoiceChip(
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                selectedCategory = category;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('Rating: ${rating.toInt()} Stars'),
                    Slider(
                      value: rating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: rating.toInt().toString(),
                      onChanged: (value) {
                        setModalState(() {
                          rating = value;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty) {
                          Meal savedMeal;
                          if (mealToEdit == null) {
                            savedMeal = Meal(
                              title: titleController.text,
                              description: descController.text,
                              category: selectedCategory,
                              rating: rating.toInt(),
                              imagePath: selectedImagePath,
                            );
                            setState(() {
                              _allMeals.add(savedMeal);
                            });
                          } else {
                            savedMeal = mealToEdit.copyWith(
                              title: titleController.text,
                              description: descController.text,
                              category: selectedCategory,
                              rating: rating.toInt(),
                              imagePath: selectedImagePath,
                            );
                            setState(() {
                              final index = _allMeals.indexOf(mealToEdit);
                              if (index != -1) {
                                _allMeals[index] = savedMeal;
                              }
                            });
                          }

                          setState(() {
                            _filterMeals();
                            _loadPage();
                          });

                          await _dataService.saveMeal(savedMeal);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                          mealToEdit == null ? 'Save Meal' : 'Update Meal'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
