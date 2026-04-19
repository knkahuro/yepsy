import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../services/task_service.dart';
import '../../../core/services/tutorial_service.dart';

/// Main screen for tracking and managing tasks.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with WidgetsBindingObserver {
  final TaskService _dataService = TaskService();
  final List<ActivityTask> _allTasks = [];

  List<ActivityTask> _filteredTasks = [];
  List<ActivityTask> _displayedTasks = []; // Paginated subset
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

  // Tutorial Keys
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _categoryBarKey = GlobalKey();
  final TutorialService _tutorialService = TutorialService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _loadTasks();
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
      _loadTasks();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreTasks();
      }
    }
  }

  Future<void> _loadTasks() async {
    try {
      await _dataService.init();
      final tasks = await _dataService.getAllTasks();

      // Simulate network delay to show skeleton
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _allTasks.clear();
          _allTasks.addAll(tasks);
          _filterTasks();
          _loadPage();
          _isLoading = false;
        });
        _checkTutorial();
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    }
  }

  void _loadPage() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= _filteredTasks.length) {
      setState(() => _hasMoreData = false);
      return;
    }

    setState(() {
      _displayedTasks.addAll(
        _filteredTasks.sublist(
          startIndex,
          endIndex > _filteredTasks.length ? _filteredTasks.length : endIndex,
        ),
      );
      _hasMoreData = endIndex < _filteredTasks.length;
    });
  }

  Future<void> _loadMoreTasks() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    _loadPage();

    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _checkTutorial() async {
    if (await _tutorialService.shouldShowTasksTutorial()) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _tutorialService.showTasksTutorial(
          context: context,
          addKey: _addButtonKey,
          categoryKey: _categoryBarKey,
        );
      });
    }
  }

  void _filterTasks() {
    final now = DateTime.now();
    setState(() {
      _filteredTasks = _allTasks.where((m) {
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
      _filteredTasks.sort((a, b) {
        final aCompleted = _dataService.isCompletedOnDate(a, now);
        final bCompleted = _dataService.isCompletedOnDate(b, now);
        if (aCompleted == bCompleted) {
          return 0;
        }
        return aCompleted ? 1 : -1;
      });

      // Reset pagination
      _currentPage = 0;
      _displayedTasks = [];
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
          'Tasks',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            key: _addButtonKey,
            onPressed: () => _showTaskForm(context),
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
                            'assets/images/task.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: MessageBubble(
                              message: 'Let\'s get things done!',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterTasks();
                          _loadPage(); // Load first page after filter
                        },
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
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
                        key: _categoryBarKey,
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
                                    _filterTasks();
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
                  child: _displayedTasks.isEmpty
                      ? const EmptyStateWidget(
                          message: 'No tasks yet. Start a new one!',
                          icon: Icons.check_circle_outline,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _displayedTasks.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the end
                            if (index == _displayedTasks.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final task = _displayedTasks[index];
                            return Dismissible(
                              key: ValueKey(task.id),
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
                                final deletedTask = task;

                                // Optimistically remove from UI
                                setState(() {
                                  _allTasks.remove(task);
                                  _filterTasks();
                                  _loadPage();
                                });

                                // Show SnackBar immediately
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 4),
                                    content: const Text('ActivityTask deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        // Restore to UI
                                        setState(() {
                                          _allTasks.add(deletedTask);
                                          _filterTasks();
                                          _loadPage();
                                        });
                                        // Re-save to DB
                                        await _dataService
                                            .saveTask(deletedTask);
                                      },
                                    ),
                                  ),
                                );

                                // Persist deletion in background
                                try {
                                  await _dataService.deleteTask(task.id);
                                } catch (e) {
                                  debugPrint('Error deleting task: $e');
                                  // Optionally show error snackbar or restore item
                                }
                              },
                              child: TaskTile(
                                task: task,
                                isCompleted: _dataService.isCompletedOnDate(
                                    task, DateTime.now()),
                                onToggleCompletion: (val) async {
                                  final updatedTask =
                                      await _dataService.toggleCompletion(
                                          task.id, DateTime.now());
                                  if (updatedTask != null) {
                                    setState(() {
                                      final index = _allTasks
                                          .indexWhere((h) => h.id == task.id);
                                      if (index != -1) {
                                        _allTasks[index] = updatedTask;
                                      }
                                      _filterTasks();
                                      _loadPage();
                                    });
                                  }
                                },
                                onEdit: () =>
                                    _showTaskForm(context, taskToEdit: task),
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

  void _showTaskForm(BuildContext context, {ActivityTask? taskToEdit}) {
    final titleController =
        TextEditingController(text: taskToEdit?.title ?? '');
    final descController =
        TextEditingController(text: taskToEdit?.description ?? '');
    String selectedCategory =
        taskToEdit?.category ?? _categories.firstWhere((c) => c != 'All');

    DateTime? taskTime = taskToEdit?.taskTime;
    List<int> frequency = taskToEdit?.frequency ?? [1, 2, 3, 4, 5, 6, 7];

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
                      taskToEdit == null ? 'Log ActivityTask' : 'Edit ActivityTask',
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
                    // ActivityTask Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.notifications,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(taskTime == null
                          ? 'Set ActivityTask'
                          : 'ActivityTask: ${taskTime!.hour.toString().padLeft(2, '0')}:${taskTime!.minute.toString().padLeft(2, '0')}'),
                      trailing: taskTime != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setModalState(() {
                                  taskTime = null;
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
                            taskTime = DateTime(
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
                          ActivityTask savedTask;
                          if (taskToEdit == null) {
                            debugPrint('Creating new task');
                            savedTask = ActivityTask(
                              title: titleController.text,
                              description: descController.text,
                              category: selectedCategory,
                              taskTime: taskTime,
                              frequency: frequency,
                            );
                            setState(() {
                              _allTasks.add(savedTask);
                            });
                          } else {
                            debugPrint(
                                'Updating existing task: ${taskToEdit.id}');
                            savedTask = taskToEdit.copyWith(
                              title: titleController.text,
                              description: descController.text,
                              category: selectedCategory,
                              taskTime: taskTime,
                              frequency: frequency,
                            );
                            setState(() {
                              final index = _allTasks.indexOf(taskToEdit);
                              if (index != -1) {
                                _allTasks[index] = savedTask;
                              }
                            });
                          }

                          setState(() {
                            _filterTasks();
                            _loadPage();
                          });

                          debugPrint('Saving task to database...');
                          await _dataService.saveTask(savedTask);
                          debugPrint('ActivityTask saved.');
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
                          taskToEdit == null ? 'Save ActivityTask' : 'Update ActivityTask'),
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
