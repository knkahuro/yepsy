import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../models/habit.dart';
import '../widgets/habit_tile.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../services/habit_service.dart';

/// Main screen for tracking and managing habits.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with WidgetsBindingObserver {
  final HabitService _dataService = HabitService();
  final List<Habit> _allHabits = [];

  List<Habit> _filteredHabits = [];
  List<Habit> _displayedHabits = []; // Paginated subset
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<String> _categories = [
    'All',
    'Work',
    'Productivity',
    'Wellness',
    'Other'
  ];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _loadHabits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHabits();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreHabits();
      }
    }
  }

  Future<void> _loadHabits() async {
    try {
      await _dataService.init();
      final habits = await _dataService.getAllHabits();

      // Simulate network delay to show skeleton
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _allHabits.clear();
          _allHabits.addAll(habits);
          _filterHabits();
          _loadPage();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load habits: $e')),
        );
      }
    }
  }

  void _loadPage() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= _filteredHabits.length) {
      setState(() => _hasMoreData = false);
      return;
    }

    setState(() {
      _displayedHabits.addAll(
        _filteredHabits.sublist(
          startIndex,
          endIndex > _filteredHabits.length ? _filteredHabits.length : endIndex,
        ),
      );
      _hasMoreData = endIndex < _filteredHabits.length;
    });
  }

  Future<void> _loadMoreHabits() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    _loadPage();

    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _filterHabits() {
    final now = DateTime.now();
    setState(() {
      _filteredHabits = _allHabits.where((m) {
        final matchesCategory =
            _selectedCategory == 'All' || m.category == _selectedCategory;
        final matchesSearch = m.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            m.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final isDueToday = m.frequency.contains(now.weekday);
        return matchesCategory && matchesSearch && isDueToday;
      }).toList();

      // Sort: Pending first, then Completed
      _filteredHabits.sort((a, b) {
        final aCompleted = _dataService.isCompletedOnDate(a, now);
        final bCompleted = _dataService.isCompletedOnDate(b, now);
        if (aCompleted == bCompleted) {
          return 0;
        }
        return aCompleted ? 1 : -1;
      });

      // Reset pagination
      _currentPage = 0;
      _displayedHabits = [];
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
          'Habits',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showHabitForm(context),
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
                            'assets/images/habit.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: MessageBubble(
                              message: 'New year, new me!',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterHabits();
                          _loadPage(); // Load first page after filter
                        },
                        decoration: InputDecoration(
                          hintText: 'Search habits...',
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
                                    _filterHabits();
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
                  child: _displayedHabits.isEmpty
                      ? const EmptyStateWidget(
                          message: 'No habits yet. Start a new one!',
                          icon: Icons.check_circle_outline,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _displayedHabits.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the end
                            if (index == _displayedHabits.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final habit = _displayedHabits[index];
                            return Dismissible(
                              key: ValueKey(habit.id),
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
                                final deletedHabit = habit;

                                // Optimistically remove from UI
                                setState(() {
                                  _allHabits.remove(habit);
                                  _filterHabits();
                                  _loadPage();
                                });

                                // Show SnackBar immediately
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 4),
                                    content: const Text('Habit deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        // Restore to UI
                                        setState(() {
                                          _allHabits.add(deletedHabit);
                                          _filterHabits();
                                          _loadPage();
                                        });
                                        // Re-save to DB
                                        await _dataService
                                            .saveHabit(deletedHabit);
                                      },
                                    ),
                                  ),
                                );

                                // Persist deletion in background
                                try {
                                  await _dataService.deleteHabit(habit.id);
                                } catch (e) {
                                  debugPrint('Error deleting habit: $e');
                                  // Optionally show error snackbar or restore item
                                }
                              },
                              child: HabitTile(
                                habit: habit,
                                isCompleted: _dataService.isCompletedOnDate(
                                    habit, DateTime.now()),
                                onToggleCompletion: (val) async {
                                  final updatedHabit =
                                      await _dataService.toggleCompletion(
                                          habit.id, DateTime.now());
                                  if (updatedHabit != null) {
                                    setState(() {
                                      final index = _allHabits
                                          .indexWhere((h) => h.id == habit.id);
                                      if (index != -1) {
                                        _allHabits[index] = updatedHabit;
                                      }
                                      _filterHabits();
                                      _loadPage();
                                    });
                                  }
                                },
                                onEdit: () =>
                                    _showHabitForm(context, habitToEdit: habit),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Weekday Selector Widget
  Widget _buildWeekdaySelector(
      List<int> selectedDays, Function(List<int>) onChanged) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = selectedDays.contains(dayIndex);
        return GestureDetector(
          onTap: () {
            final newSelection = List<int>.from(selectedDays);
            if (isSelected) {
              if (newSelection.length > 1) newSelection.remove(dayIndex);
            } else {
              newSelection.add(dayIndex);
              newSelection.sort();
            }
            onChanged(newSelection);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              shape: BoxShape.circle,
              border:
                  isSelected ? null : Border.all(color: Colors.grey.shade400),
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showHabitForm(BuildContext context, {Habit? habitToEdit}) {
    final titleController =
        TextEditingController(text: habitToEdit?.title ?? '');
    final descController =
        TextEditingController(text: habitToEdit?.description ?? '');
    String selectedCategory =
        habitToEdit?.category ?? _categories.firstWhere((c) => c != 'All');

    DateTime? reminderTime = habitToEdit?.reminderTime;
    List<int> frequency = habitToEdit?.frequency ?? [1, 2, 3, 4, 5, 6, 7];

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
                      habitToEdit == null ? 'Log Habit' : 'Edit Habit',
                      style: AppTypography.displayTextTheme.titleMedium,
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
                    const SizedBox(height: 16),
                    // Frequency Selector
                    const Text('Schedule',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildWeekdaySelector(frequency, (newFreq) {
                      setModalState(() => frequency = newFreq);
                    }),
                    const SizedBox(height: 12),
                    // Reminder Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.notifications,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(reminderTime == null
                          ? 'Set Reminder'
                          : 'Reminder: ${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}'),
                      trailing: reminderTime != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setModalState(() {
                                  reminderTime = null;
                                });
                              },
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setModalState(() {
                            final now = DateTime.now();
                            reminderTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        debugPrint('Save button pressed');
                        if (titleController.text.isNotEmpty) {
                          debugPrint('Title is valid: ${titleController.text}');
                          Habit savedHabit;
                          if (habitToEdit == null) {
                            debugPrint('Creating new habit');
                            savedHabit = Habit(
                              title: titleController.text,
                              description: descController.text,
                              category: selectedCategory,
                              reminderTime: reminderTime,
                              frequency: frequency,
                            );
                            setState(() {
                              _allHabits.add(savedHabit);
                            });
                          } else {
                            debugPrint(
                                'Updating existing habit: ${habitToEdit.id}');
                            savedHabit = habitToEdit.copyWith(
                              title: titleController.text,
                              description: descController.text,
                              category: selectedCategory,
                              reminderTime: reminderTime,
                              frequency: frequency,
                            );
                            setState(() {
                              final index = _allHabits.indexOf(habitToEdit);
                              if (index != -1) {
                                _allHabits[index] = savedHabit;
                              }
                            });
                          }

                          setState(() {
                            _filterHabits();
                            _loadPage();
                          });

                          debugPrint('Saving habit to database...');
                          await _dataService.saveHabit(savedHabit);
                          debugPrint('Habit saved.');
                          if (context.mounted) {
                            debugPrint('Closing modal');
                            Navigator.pop(context);
                          }
                        } else {
                          debugPrint('Title is empty');
                          // Show error if title is empty
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a title')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                          habitToEdit == null ? 'Save Habit' : 'Update Habit'),
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
