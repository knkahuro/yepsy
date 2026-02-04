import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../models/note.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../widgets/note_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../services/notes_data_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesDataService _dataService = NotesDataService();
  final List<Note> _allNotes = [];

  List<Note> _filteredNotes = [];
  List<Note> _displayedNotes = []; // Paginated subset
  String _searchQuery = '';
  Mood? _selectedMood;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotes();
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
        _loadMoreNotes();
      }
    }
  }

  Future<void> _loadNotes() async {
    await _dataService.init();
    final notes = await _dataService.getAllNotes();

    // Simulate network delay to show skeleton
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _allNotes.clear();
        _allNotes.addAll(notes);
        _filterNotes();
        _loadPage();
        _isLoading = false;
      });
    }
  }

  void _loadPage() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= _filteredNotes.length) {
      setState(() => _hasMoreData = false);
      return;
    }

    setState(() {
      _displayedNotes.addAll(
        _filteredNotes.sublist(
          startIndex,
          endIndex > _filteredNotes.length ? _filteredNotes.length : endIndex,
        ),
      );
      _hasMoreData = endIndex < _filteredNotes.length;
    });
  }

  Future<void> _loadMoreNotes() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    _loadPage();

    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _filterNotes() {
    setState(() {
      _filteredNotes = _allNotes.where((note) {
        final matchesSearch =
            note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                note.message.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesMood = _selectedMood == null || note.mood == _selectedMood;
        return matchesSearch && matchesMood;
      }).toList();

      // Sort: Pinned first
      // Sort: Pinned first, then by date (latest first)
      _filteredNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        // If both pinned or both unpinned, sort by date desc
        if (a.date != null && b.date != null) {
          return b.date!.compareTo(a.date!);
        }
        return 0;
      });

      // Reset pagination
      _currentPage = 0;
      _displayedNotes = [];
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
          'Notes',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddNoteForm(context),
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
                            'assets/images/notes.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: MessageBubble(
                              message:
                                  'I hope you are having a wonderful day !',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterNotes();
                          _loadPage(); // Load first page after filter
                        },
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
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
                      // Mood Filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All'),
                                selected: _selectedMood == null,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedMood = null;
                                    _filterNotes();
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
                              ),
                            ),
                            ...Mood.values.map((mood) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(_getMoodEmoji(mood)),
                                  selected: _selectedMood == mood,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      _selectedMood = selected ? mood : null;
                                      _filterNotes();
                                      _loadPage(); // Reload paginated display
                                    });
                                  },
                                  backgroundColor: Colors.grey[100],
                                  selectedColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  checkmarkColor:
                                      Theme.of(context).colorScheme.primary,
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: _selectedMood == mood
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _displayedNotes.isEmpty
                      ? const EmptyStateWidget(
                          message: 'No notes found. Create one!',
                          icon: Icons.note_add_outlined,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount:
                              _displayedNotes.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the end
                            if (index == _displayedNotes.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final note = _displayedNotes[index];
                            return Dismissible(
                              key: ValueKey(note.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
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
                                final deletedNote = note;
                                setState(() {
                                  _allNotes.remove(note);
                                  _filterNotes();
                                  _loadPage();
                                });
                                await _dataService.deleteNote(note.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    content: const Text('Note deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        setState(() {
                                          _allNotes.add(deletedNote);
                                          _filterNotes();
                                          _loadPage();
                                        });
                                        await _dataService
                                            .saveNote(deletedNote);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: NoteTile(
                                note: note,
                                onPinTap: () async {
                                  final newNote =
                                      note.copyWith(isPinned: !note.isPinned);
                                  setState(() {
                                    final index = _allNotes.indexOf(note);
                                    if (index != -1) {
                                      _allNotes[index] = newNote;
                                      _filterNotes();
                                      _loadPage();
                                    }
                                  });
                                  await _dataService.saveNote(newNote);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _getMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return '😊';
      case Mood.sad:
        return '😢';
      case Mood.neutral:
        return '😐';
      case Mood.excited:
        return '🤩';
      case Mood.tired:
        return '😴';
    }
  }

  void _showAddNoteForm(BuildContext context) {
    String title = '';
    String message = '';
    Mood selectedMood = Mood.happy;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add New Note',
                    style: AppTypography.displayTextTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => message = value,
                  ),
                  const SizedBox(height: 12),
                  const Text('Mood:'),
                  Wrap(
                    spacing: 8,
                    children: Mood.values.map((mood) {
                      return ChoiceChip(
                        label: Text(_getMoodEmoji(mood)),
                        selected: selectedMood == mood,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedMood = mood;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (title.isNotEmpty && message.isNotEmpty) {
                        final newNote = Note(
                          title: title,
                          message: message,
                          mood: selectedMood,
                          date: DateTime.now(),
                        );
                        setState(() {
                          _allNotes.add(newNote);
                          _filterNotes();
                          _loadPage();
                        });
                        await _dataService.saveNote(newNote);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Note'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
