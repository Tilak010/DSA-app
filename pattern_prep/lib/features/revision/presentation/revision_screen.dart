import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../patterns/models/pattern_model.dart';
import '../models/revision_task_model.dart';

enum RevisionSortOption {
  mostOverdue,
  lowestConfidence,
  leastRecentlyReviewed,
  category,
  upcomingDueDate,
}

class RevisionScreen extends ConsumerStatefulWidget {
  const RevisionScreen({super.key});

  @override
  ConsumerState<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends ConsumerState<RevisionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  RevisionSortOption _selectedSort = RevisionSortOption.mostOverdue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<RevisionTask> _filterAndSort(List<RevisionTask> tasks) {
    var result = tasks.where((t) {
      if (_selectedCategory != 'All' && t.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatus != 'All') {
        final statusStr = t.status.name.toLowerCase();
        final selectedLower = _selectedStatus.toLowerCase().replaceAll(' ', '');
        if (statusStr != selectedLower) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      switch (_selectedSort) {
        case RevisionSortOption.mostOverdue:
          return b.daysOverdue.compareTo(a.daysOverdue);
        case RevisionSortOption.lowestConfidence:
          final aVal = a.lastConfidence?.index ?? 99;
          final bVal = b.lastConfidence?.index ?? 99;
          return aVal.compareTo(bVal);
        case RevisionSortOption.leastRecentlyReviewed:
          final aDate = a.lastReviewedAt ?? DateTime(1970);
          final bDate = b.lastReviewedAt ?? DateTime(1970);
          return aDate.compareTo(bDate);
        case RevisionSortOption.category:
          return a.category.compareTo(b.category);
        case RevisionSortOption.upcomingDueDate:
          final aDate = a.nextReviewDate ?? DateTime(2099);
          final bDate = b.nextReviewDate ?? DateTime(2099);
          return aDate.compareTo(bDate);
      }
    });

    return result;
  }

  Future<void> _changeNextReviewDate(BuildContext context, RevisionTask task) async {
    final now = DateTime.now();
    final initial = task.nextReviewDate ?? now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentBlue,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.card),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final srs = ref.read(spacedRepetitionServiceProvider);
      final normalized = srs.normalizeDate(picked);
      await ref.read(patternDetailsProvider.notifier).updateNextReviewDate(
            task.patternId,
            normalized,
          );

      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated next review for "${task.patternName}" to ${normalized.day}/${normalized.month}/${normalized.year}',
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = ref.watch(dueTodayTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final upcomingTasks = ref.watch(upcomingTasksProvider);
    final recentTasks = ref.watch(recentlyReviewedTasksProvider);
    final dailyQueue = ref.watch(dailyQueueProvider);
    final stats = ref.watch(revisionStatsProvider);

    // Unique categories from tasks
    final allTasks = ref.watch(revisionTasksProvider);
    final categories = {'All', ...allTasks.map((t) => t.category)}.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Revision Planner',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.accentBlue),
            tooltip: 'Revision History',
            onPressed: () => context.push('/progress/history'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Due (${todayTasks.length})'),
            Tab(text: 'Overdue (${overdueTasks.length})'),
            Tab(text: 'Upcoming (${upcomingTasks.length})'),
            Tab(text: 'Recent (${recentTasks.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDailyGoalHeader(stats, dailyQueue),
          _buildFilterAndSortBar(categories),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(
                  tasks: _filterAndSort(todayTasks),
                  emptyTitle: 'No Patterns Due Today! 🎉',
                  emptySubtitle:
                      'You are completely caught up. Keep your momentum going by revising a weak or unreviewed pattern.',
                  emptyActionText: 'Revise Recommended Pattern',
                  onEmptyAction: () {
                    final next = dailyQueue.firstOrNull;
                    if (next != null) {
                      context.push('/patterns/${next.id}/quick-review');
                    }
                  },
                ),
                _buildTaskList(
                  tasks: _filterAndSort(overdueTasks),
                  emptyTitle: 'No Overdue Patterns! 🏆',
                  emptySubtitle:
                      'All patterns are reviewed on schedule. Fantastic job sticking to spaced repetition intervals.',
                  emptyActionText: null,
                  onEmptyAction: null,
                ),
                _buildTaskList(
                  tasks: _filterAndSort(upcomingTasks),
                  emptyTitle: 'No Upcoming Reviews',
                  emptySubtitle:
                      'As you complete pattern revision sessions, future reviews will automatically be scheduled here.',
                  emptyActionText: null,
                  onEmptyAction: null,
                ),
                _buildTaskList(
                  tasks: _filterAndSort(recentTasks),
                  emptyTitle: 'No Recently Reviewed Patterns',
                  emptySubtitle:
                      'Patterns you revise will show up here along with their latest confidence ratings.',
                  emptyActionText: null,
                  onEmptyAction: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalHeader(RevisionStats stats, List<PatternSummary> dailyQueue) {
    final progress = stats.dailyRevisionGoal > 0
        ? (stats.todayCompletedCount / stats.dailyRevisionGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Revision Goal",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.todayCompletedCount} of ${stats.dailyRevisionGoal} patterns reviewed today',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final next = dailyQueue.firstOrNull;
                  if (next != null) {
                    context.push('/patterns/${next.id}/quick-review');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No patterns in revision queue!')),
                    );
                  }
                },
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('Start Revision'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.card,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.accentEmerald : AppColors.accentBlue,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortBar(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Category filter
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: AppColors.surface,
                labelText: 'Category',
                labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Status filter
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: AppColors.surface,
                labelText: 'Status',
                labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: ['All', 'Needs Revision', 'Learning', 'Reviewed', 'Mastered']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Sort Menu
          PopupMenuButton<RevisionSortOption>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.accentBlue, size: 22),
            tooltip: 'Sort Tasks',
            color: AppColors.surface,
            onSelected: (opt) => setState(() => _selectedSort = opt),
            itemBuilder: (context) => [
              _sortMenuItem(RevisionSortOption.mostOverdue, 'Most Overdue'),
              _sortMenuItem(RevisionSortOption.lowestConfidence, 'Lowest Confidence'),
              _sortMenuItem(RevisionSortOption.leastRecentlyReviewed, 'Least Recently Reviewed'),
              _sortMenuItem(RevisionSortOption.category, 'Category'),
              _sortMenuItem(RevisionSortOption.upcomingDueDate, 'Upcoming Due Date'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<RevisionSortOption> _sortMenuItem(RevisionSortOption opt, String label) {
    final isSelected = _selectedSort == opt;
    return PopupMenuItem(
      value: opt,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList({
    required List<RevisionTask> tasks,
    required String emptyTitle,
    required String emptySubtitle,
    required String? emptyActionText,
    required VoidCallback? onEmptyAction,
  }) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.done_all_rounded, size: 54, color: AppColors.accentEmerald.withValues(alpha: 0.8)),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              if (emptyActionText != null && onEmptyAction != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onEmptyAction,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(emptyActionText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(RevisionTask task) {
    final completionPct = (task.checklistPercentage * 100).toInt();
    final lastRevStr = task.lastReviewedAt != null
        ? '${task.lastReviewedAt!.day}/${task.lastReviewedAt!.month}/${task.lastReviewedAt!.year}'
        : 'Never';
    final nextRevStr = task.nextReviewDate != null
        ? '${task.nextReviewDate!.day}/${task.nextReviewDate!.month}/${task.nextReviewDate!.year}'
        : 'Not scheduled';

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: task.due == RevisionDue.overdue
              ? AppColors.error.withValues(alpha: 0.4)
              : (task.due == RevisionDue.today
                  ? AppColors.accentAmber.withValues(alpha: 0.4)
                  : AppColors.cardBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.category,
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(task.status),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Manually change next review date',
                  onPressed: () => _changeNextReviewDate(context, task),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.patternName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Metrics grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Last Reviewed',
                    lastRevStr,
                    Icons.history,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Next Review',
                    nextRevStr,
                    Icons.event,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Checklist',
                    '$completionPct% complete',
                    Icons.checklist,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Last Confidence',
                    task.lastConfidence?.label ?? 'None yet',
                    Icons.star_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.checklistPercentage,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.checklistPercentage >= 0.8 ? AppColors.accentEmerald : AppColors.accentBlue,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.dueLabel ?? '',
                  style: TextStyle(
                    color: task.due == RevisionDue.overdue
                        ? AppColors.error
                        : (task.due == RevisionDue.today
                            ? AppColors.accentAmber
                            : AppColors.textSecondary),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/patterns/${task.patternId}/quick-review');
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Revise Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LearningStatus status) {
    Color color;
    switch (status) {
      case LearningStatus.notStarted:
        color = AppColors.textSecondary;
        break;
      case LearningStatus.learning:
        color = AppColors.accentBlue;
        break;
      case LearningStatus.needsRevision:
        color = AppColors.error;
        break;
      case LearningStatus.reviewed:
        color = AppColors.accentEmerald;
        break;
      case LearningStatus.mastered:
        color = Colors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
