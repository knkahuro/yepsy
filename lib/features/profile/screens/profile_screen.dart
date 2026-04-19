import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../theme/typography.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../../calendar/services/export_service.dart';
import '../../calendar/services/import_service.dart';
import '../../calendar/services/notification_service.dart';
import '../../calendar/services/calendar_data_service.dart';
import '../../../theme/theme_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/section_title.dart';
import '../widgets/option_tile.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/database/database_service.dart';

import 'version_features_page.dart';
import 'how_it_works_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _dataService = CalendarDataService();
  late final ExportService _exportService;
  late final ImportService _importService;
  final _notificationService = NotificationService();

  bool _periodTasksEnabled = false;
  bool _ovulationTasksEnabled = false;
  int _taskDaysBefore = 2;
  bool _isLoading = true;
  int _currentStreak = 0;

  // Biometric settings
  final BiometricService _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometric';

  final EncryptionService _encryptionService = EncryptionService();

  @override
  void initState() {
    super.initState();
    _exportService = ExportService(_dataService, _encryptionService);
    _importService = ImportService(_dataService, _encryptionService);
    _loadData();
  }

  Future<void> _loadData() async {
    await _dataService.init();
    await _notificationService.initialize();

    final prefs = await NotificationService.getPreferences();
    if (mounted) {
      setState(() {
        _periodTasksEnabled = prefs['periodTasksEnabled'];
        _ovulationTasksEnabled = prefs['ovulationTasksEnabled'];
        _taskDaysBefore = prefs['taskDaysBefore'];
        _isLoading = false;
      });

      // Load biometric settings
      _loadBiometricSettings();

      // Load encryption settings
      _loadEncryptionSettings();

      // Load streak
      _loadStreak();
    }
  }

  Future<void> _loadStreak() async {
    final streakService = StreakService();
    final streak = await streakService.calculateCurrentStreak();
    if (mounted) {
      setState(() {
        _currentStreak = streak;
      });
    }
  }

  Future<void> _loadEncryptionSettings() async {
    await _encryptionService.initialize();
  }

  Future<void> _loadBiometricSettings() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    final types = await _biometricService.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricType = _biometricService.getBiometricTypeName(types);
      });
    }
  }

  Future<void> _exportToJson() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _exportService.exportToJson();
      await _exportService.shareExportedFile(file);

      messenger.showSnackBar(
        const SnackBar(content: Text('Data exported successfully!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _exportToCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _exportService.exportToCsv();
      await _exportService.shareExportedFile(file);

      messenger.showSnackBar(
        const SnackBar(content: Text('CSV exported successfully!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importData() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension;

      if (!mounted) return;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'This will add the imported data to your existing data. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final importResult = extension == 'json'
          ? await _importService.importFromJson(file)
          : await _importService.importFromCsv(file);

      if (mounted) {
        if (importResult.success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Successful'),
              content: Text(
                'Events imported: ${importResult.eventsImported}\n'
                'Symptoms imported: ${importResult.symptomsImported}\n'
                'Cycle data: ${importResult.cycleDataImported ? "Yes" : "No"}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(importResult.message)),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _togglePeriodTasks(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
        return;
      }
    }

    setState(() => _periodTasksEnabled = value);
    await NotificationService.savePreferences(periodTasksEnabled: value);

    if (value) {
      final cycleProfile = await _dataService.getOrCreateCycleProfile();
      await _notificationService.schedulePeriodTask(
        cycleProfile,
        _taskDaysBefore,
      );
    } else {
      await _notificationService.cancelNotification(0);
    }
  }

  Future<void> _toggleOvulationTasks(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
        return;
      }
    }

    setState(() => _ovulationTasksEnabled = value);
    await NotificationService.savePreferences(ovulationTasksEnabled: value);

    if (value) {
      final cycleProfile = await _dataService.getOrCreateCycleProfile();
      await _notificationService.scheduleOvulationTask(cycleProfile);
    } else {
      await _notificationService.cancelNotification(1);
    }
  }

  Future<void> _updateTaskDays(int days) async {
    setState(() => _taskDaysBefore = days);
    await NotificationService.savePreferences(taskDaysBefore: days);

    if (_periodTasksEnabled) {
      final cycleProfile = await _dataService.getOrCreateCycleProfile();
      await _notificationService.schedulePeriodTask(
        cycleProfile,
        days,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          title: Text(
            'Profile',
            style: AppTypography.displayTextTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
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
              const SizedBox(height: 24),
              // Streak Skeleton
              SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.circular(16)),
              const SizedBox(height: 24),
              // Settings Skeleton
              Expanded(
                child: Column(
                  children: [
                    SkeletonLoader.text(height: 60),
                    const SizedBox(height: 12),
                    SkeletonLoader.text(height: 60),
                    const SizedBox(height: 12),
                    SkeletonLoader.text(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/activity.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: MessageBubble(
                    message: 'Hee...hee',
                  ),
                ),
              ],
            ),
            // Streaks
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Streak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$_currentStreak ${_currentStreak == 1 ? 'Day' : 'Days'}',
                        style: AppTypography.displayTextTheme.headlineSmall
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Customization Options
            const SectionTitle(title: 'Customization'),
            const SizedBox(height: 12),
            OptionTile(
              icon: Icons.palette_outlined,
              title: 'App Theme',
              subtitle: 'Customize accent color',
              onTap: _showThemePicker,
            ),

            const SizedBox(height: 24),

            // Security Section
            const SectionTitle(title: 'Security'),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      Icons.fingerprint,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text('$_biometricType Lock'),
                    subtitle: Text(
                      _biometricAvailable
                          ? 'Unlock app with $_biometricType'
                          : 'Biometric authentication not available',
                    ),
                    value: _biometricEnabled,
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    onChanged: _biometricAvailable
                        ? (value) async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (value) {
                              // Show PIN setup dialog
                              final pin = await _showPinSetupDialog();
                              if (pin != null) {
                                await _biometricService.setPin(pin);
                                await _biometricService.enableBiometric();
                                setState(() => _biometricEnabled = true);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('$_biometricType lock enabled'),
                                  ),
                                );
                              }
                            } else {
                              await _biometricService.disableBiometric();
                              setState(() => _biometricEnabled = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text('$_biometricType lock disabled'),
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                  const Divider(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications Section
            const SectionTitle(title: 'Notifications'),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.notifications,
                        color: Theme.of(context).colorScheme.primary),
                    title: const Text('Period Tasks'),
                    subtitle: const Text('Get notified before your period'),
                    value: _periodTasksEnabled,
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    onChanged: _togglePeriodTasks,
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.favorite, color: Colors.purple),
                    title: const Text('Ovulation Tasks'),
                    subtitle: const Text('Get notified during fertile window'),
                    value: _ovulationTasksEnabled,
                    activeTrackColor: Colors.purple,
                    onChanged: _toggleOvulationTasks,
                  ),
                  if (_periodTasksEnabled) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remind me $_taskDaysBefore ${_taskDaysBefore == 1 ? 'day' : 'days'} before',
                            style: AppTypography.textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _taskDaysBefore.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            activeColor: Theme.of(context).colorScheme.primary,
                            label: '$_taskDaysBefore days',
                            onChanged: (value) =>
                                _updateTaskDays(value.toInt()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Data Management Section
            const SectionTitle(title: 'Data Management'),
            const SizedBox(height: 12),
            OptionTile(
              icon: Icons.file_download_outlined,
              title: 'Export to JSON',
              subtitle: 'Backup all your data',
              onTap: _exportToJson,
            ),
            const SizedBox(height: 12),
            OptionTile(
              icon: Icons.table_chart_outlined,
              title: 'Export to CSV',
              subtitle: 'Spreadsheet-compatible format',
              onTap: _exportToCsv,
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            OptionTile(
              icon: Icons.download_outlined,
              title: 'Import Data',
              subtitle: 'Restore from backup file',
              onTap: _importData,
            ),
            const SizedBox(height: 12),
            OptionTile(
              icon: Icons.delete_forever_outlined,
              title: 'Delete All Data',
              subtitle: 'Permanently erase all app data',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: _deleteAllData,
            ),

            const SizedBox(height: 32),
            const SectionTitle(title: 'About'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HowItWorksPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it Works',
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Predictions & Privacy',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VersionFeaturesPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yepsy',
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Version 1.0.0',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select App Theme',
                style: AppTypography.displayTextTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFC56078)),
                title: const Text('Pink (Default)'),
                onTap: () => _updateTheme(const Color(0xFFC56078)),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF567CD7)),
                title: const Text('Calm Blue'),
                onTap: () => _updateTheme(const Color(0xFF567CD7)),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF8E44AD)),
                title: const Text('Mystic Purple'),
                onTap: () => _updateTheme(const Color(0xFF8E44AD)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateTheme(Color color) async {
    Navigator.pop(context); // Close sheet
    await ThemeService.saveThemeColor(color);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme saved. Please restart the app to apply changes.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<String?> _showPinSetupDialog() async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    String? errorMessage;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set up PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create a 4-digit PIN as a backup to unlock the app',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  errorText: errorMessage,
                  counterText: '',
                ),
                onChanged: (_) => setDialogState(() => errorMessage = null),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pin = pinController.text;
                final confirm = confirmController.text;

                if (pin.length != 4) {
                  setDialogState(() => errorMessage = 'PIN must be 4 digits');
                  return;
                }

                if (pin != confirm) {
                  setDialogState(() => errorMessage = 'PINs do not match');
                  return;
                }

                Navigator.pop(context, pin);
              },
              child: const Text('Set PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all your entries, settings, and preferences. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Double check
      final doubleConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: const Text(
            'All data will be lost forever. The app will restart as if new.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Delete All'),
            ),
          ],
        ),
      );

      if (doubleConfirmed == true && mounted) {
        // Navigate to a clean slate immediately to unmount all Hive boxes users
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const _ResettingAppScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    }
  }
}

class _ResettingAppScreen extends StatefulWidget {
  const _ResettingAppScreen();

  @override
  State<_ResettingAppScreen> createState() => _ResettingAppScreenState();
}

class _ResettingAppScreenState extends State<_ResettingAppScreen> {
  @override
  void initState() {
    super.initState();
    _performReset();
  }

  Future<void> _performReset() async {
    // Give time for the UI to settle and previous routes to dispose
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 1. Clear Hive Database completely
      await DatabaseService.clearAllData();

      // 2. Reset Encryption Keys in Memory
      final encryptionService = EncryptionService();
      await encryptionService.resetEncryption();

      // 3. DO NOT Reset Onboarding
      // We want the user to stay "onboarded" so they don't get sample data again.
      // The database is already empty, so they will start fresh on the Home screen.

      if (mounted) {
        // Show restart dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Reset Complete'),
            content: const Text(
              'All data has been erased.\n\nThe app will now close. Please restart it to begin fresh setup.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('Close App'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting data: $e')),
        );
        // Navigate back to onboarding or some safe state if possible,
        // but since we might have partially deleted things, it's safer to just tell them to restart.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Resetting App...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we clear your data',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
