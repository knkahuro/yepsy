import 'package:flutter/material.dart';
import 'package:yepsy/features/sleep_tracking/widgets/sleep_log_form.dart';

import '../../../../theme/typography.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../services/sleep_data_service.dart';
import '../models/sleep_log.dart';
import '../widgets/sleep_graph.dart';
import '../widgets/sleep_insights_widget.dart'; // Import Insights Widget

import '../../../shared/widgets/skeleton_loader.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  final SleepDataService _dataService = SleepDataService();
  final ScrollController _scrollController =
      ScrollController(); // Keep if we want scrollable screen

  // Changed: No longer tracking list of specific logs for UI
  Map<String, dynamic> _insights = {};
  List<SleepLog> _recentLogs = [];
  double _avgDuration = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _dataService.init();
    final insights = await _dataService.getSleepInsights();
    final recentLogs = await _dataService.getRecentLogs();
    final avgDuration = await _dataService.getAverageSleepDuration();

    setState(() {
      _insights = insights;
      _recentLogs = recentLogs;
      _avgDuration = avgDuration;
      _isLoading = false;
    });
  }

  // Note: Delete log is trickier without a list to swipe.
  // User asked to remove logs, so CRUD might be Add-only for now via UI,
  // or accessed via a different "History" page if we kept it hidden.
  // For now, removing delete capability as requested "Show insights instead".

  void _showAddSleepLog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SleepLogForm(
        onSave: (bedtime, wakeTime, quality) async {
          // Adjust dates if bedtime is after wakeTime (meaning overnight)
          DateTime finalBedtime = bedtime;
          DateTime finalWakeTime = wakeTime;

          if (finalWakeTime.isBefore(finalBedtime)) {
            finalBedtime = finalBedtime.subtract(const Duration(days: 1));
          }

          final newLog = SleepLog(
            bedtime: finalBedtime,
            wakeTime: finalWakeTime,
            quality: quality,
          );

          await _dataService.saveLog(newLog);
          _loadData();
        },
      ),
    );
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
            'Sleep tracking',
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
              // Graph Skeleton
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader.text(width: 100, height: 20),
                    const SizedBox(height: 16),
                    Expanded(
                        child: SkeletonLoader.text(height: double.infinity)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Insights Skeleton
              const SkeletonCard(),
            ],
          ),
        ),
      );
    }

    // Round to 1 decimal
    final avgString = '${_avgDuration.toStringAsFixed(1)} hrs';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Sleep tracking',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAddSleepLog,
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/sleep.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: MessageBubble(
                    message: 'I love my sleep',
                  ),
                ),
              ],
            ),
            // Sleep Goal Card removed as requested
            // const SizedBox(height: 24), // Removed spacer for card
            const SizedBox(height: 24),

            // Sleep Graph
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Last 7 Days',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Avg: $avgString',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SleepGraph(recentLogs: _recentLogs),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sleep Insights Section (Replaces History)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sleep Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                SleepInsightsWidget(insights: _insights),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
