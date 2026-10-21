import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../patterns/models/pattern_model.dart';
import '../../revision/models/revision_task_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(revisionStatsProvider);
    final patterns = ref.watch(patternsProvider);
    final todayTasks = ref.watch(dueTodayTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final upcomingTasks = ref.watch(upcomingTasksProvider);
    final recentTasks = ref.watch(recentlyReviewedTasksProvider);
    final dailyQueue = ref.watch(dailyQueueProvider);

    // Recently studied patterns (have a lastReviewedAt date)
    final recentlyStudied = patterns
        .where((p) => p.lastReviewedAt != null)
        .toList()
      ..sort((a, b) => b.lastReviewedAt!.compareTo(a.lastReviewedAt!));

    // Next pattern to continue revising from daily queue
    final nextPattern = dailyQueue.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: AppColors.background,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'PatternPrep',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Revision History',
                icon: const Icon(Icons.history_rounded, color: AppColors.accentBlue),
                onPressed: () => context.push('/progress/history'),
              ),
              IconButton(
                tooltip: 'Bookmarks',
                icon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.textSecondary),
                onPressed: () => context.push('/bookmarks'),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Greeting Header ───────────────────────────────────────
                _GreetingHeader(),
                const SizedBox(height: 18),

                // ── Today's Revision Progress Summary ─────────────────────
                _TodayRevisionCard(
                  completed: stats.todayCompletedCount,
                  target: stats.dailyRevisionGoal,
                  dueTodayCount: stats.dueTodayCount,
                  overdueCount: stats.overdueCount,
                ),
                const SizedBox(height: 18),

                // ── Prominent Action Buttons ──────────────────────────────
                _PrimaryActionButtons(
                  onStartRevision: () => context.go('/revision'),
                  onContinueRevising: () {
                    if (nextPattern != null) {
                      context.push('/patterns/${nextPattern.id}/quick-review');
                    } else {
                      context.go('/revision');
                    }
                  },
                  nextPatternName: nextPattern?.name,
                ),
                const SizedBox(height: 20),

                // ── Spaced Repetition Metrics Grid ─────────────────────────
                _RevisionStatsGrid(
                  stats: stats,
                  dueToday: stats.dueTodayCount,
                  overdue: stats.overdueCount,
                  upcoming: upcomingTasks.length,
                  recentlyReviewed: recentTasks.length,
                ),
                const SizedBox(height: 20),

                // ── Overdue Patterns Section ──────────────────────────────
                if (overdueTasks.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Overdue Patterns',
                    actionLabel: 'See Overdue (${overdueTasks.length})',
                    action: () => context.go('/revision'),
                  ),
                  const SizedBox(height: 12),
                  ...overdueTasks.take(3).map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskRevisionRowCard(task: t),
                  )),
                  const SizedBox(height: 20),
                ],

                // ── Patterns Due Today ────────────────────────────────────
                if (todayTasks.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Due Today',
                    actionLabel: 'View All (${todayTasks.length})',
                    action: () => context.go('/revision'),
                  ),
                  const SizedBox(height: 12),
                  ...todayTasks.take(3).map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskRevisionRowCard(task: t),
                  )),
                  const SizedBox(height: 20),
                ],

                // ── Patterns Needing Improvement / Weak Patterns ───────────
                if (stats.weakestPatterns.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Weak Patterns',
                    actionLabel: 'View All',
                    action: () => context.go('/progress'),
                  ),
                  const SizedBox(height: 12),
                  ...stats.weakestPatterns.take(3).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NeedingAttentionCard(pattern: p),
                  )),
                  const SizedBox(height: 20),
                ],

                // ── Recently Reviewed Patterns ────────────────────────────
                if (recentlyStudied.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Recently Reviewed',
                    actionLabel: 'History',
                    action: () => context.push('/progress/history'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentlyStudied.take(5).length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final p = recentlyStudied[i];
                        return _RecentPatternCard(pattern: p);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Upcoming Reviews ──────────────────────────────────────
                if (upcomingTasks.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Upcoming Reviews',
                    actionLabel: 'Planner',
                    action: () => context.go('/revision'),
                  ),
                  const SizedBox(height: 12),
                  ...upcomingTasks.take(3).map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskRevisionRowCard(task: t),
                  )),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Good morning ☀️' : (hour < 17 ? 'Good afternoon 🌤️' : 'Good evening 🌙');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        const Text(
          'Ready to revise patterns?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TodayRevisionCard extends StatelessWidget {
  const _TodayRevisionCard({
    required this.completed,
    required this.target,
    required this.dueTodayCount,
    required this.overdueCount,
  });

  final int completed;
  final int target;
  final int dueTodayCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Revision Goal",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$completed',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: ' / $target patterns revised today',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: progress >= 1.0 ? AppColors.success.withAlpha(25) : AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  progress >= 1.0 ? '🎉 Goal Met' : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: progress >= 1.0 ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (dueTodayCount > 0) ...[
                const Icon(Icons.today_rounded, size: 14, color: AppColors.accentBlue),
                const SizedBox(width: 4),
                Text(
                  '$dueTodayCount due today',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              if (dueTodayCount > 0 && overdueCount > 0)
                const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
              if (overdueCount > 0) ...[
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  '$overdueCount overdue',
                  style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
                ),
              ],
              if (dueTodayCount == 0 && overdueCount == 0) ...[
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                const Text(
                  'All patterns reviewed on schedule!',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButtons extends StatelessWidget {
  const _PrimaryActionButtons({
    required this.onStartRevision,
    required this.onContinueRevising,
    this.nextPatternName,
  });

  final VoidCallback onStartRevision;
  final VoidCallback onContinueRevising;
  final String? nextPatternName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onStartRevision,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Start Revision'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onContinueRevising,
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(
                  nextPatternName != null ? 'Continue Revising' : 'Continue',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevisionStatsGrid extends StatelessWidget {
  const _RevisionStatsGrid({
    required this.stats,
    required this.dueToday,
    required this.overdue,
    required this.upcoming,
    required this.recentlyReviewed,
  });

  final RevisionStats stats;
  final int dueToday;
  final int overdue;
  final int upcoming;
  final int recentlyReviewed;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _StatBox(
          value: '$dueToday',
          label: 'Due Today',
          icon: Icons.today_rounded,
          color: AppColors.accentBlue,
        ),
        _StatBox(
          value: '$overdue',
          label: 'Overdue',
          icon: Icons.alarm_on_rounded,
          color: overdue > 0 ? AppColors.error : AppColors.secondary,
        ),
        _StatBox(
          value: '$upcoming',
          label: 'Upcoming Reviews',
          icon: Icons.event_available_rounded,
          color: AppColors.warning,
        ),
        _StatBox(
          value: '$recentlyReviewed',
          label: 'Recently Reviewed',
          icon: Icons.history_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _TaskRevisionRowCard extends StatelessWidget {
  const _TaskRevisionRowCard({required this.task});
  final RevisionTask task;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/patterns/${task.patternId}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (task.due == RevisionDue.overdue ? AppColors.error : AppColors.primary).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              task.due == RevisionDue.overdue ? Icons.warning_amber_rounded : Icons.flash_on_rounded,
              color: task.due == RevisionDue.overdue ? AppColors.error : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.patternName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.category} • ${task.dueLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    color: task.due == RevisionDue.overdue ? AppColors.error : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/patterns/${task.patternId}/quick-review'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: AppColors.primary,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Revise', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _RecentPatternCard extends StatelessWidget {
  const _RecentPatternCard({required this.pattern});
  final PatternSummary pattern;

  @override
  Widget build(BuildContext context) {
    final percentInt = (pattern.checklistPercentage * 100).toInt();

    return InkWell(
      onTap: () => context.push('/patterns/${pattern.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pattern.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              pattern.category,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: pattern.status),
                Text(
                  '$percentInt%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedingAttentionCard extends StatelessWidget {
  const _NeedingAttentionCard({required this.pattern});
  final PatternSummary pattern;

  @override
  Widget build(BuildContext context) {
    final percentInt = (pattern.checklistPercentage * 100).toInt();

    return AppCard(
      onTap: () => context.push('/patterns/${pattern.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Checklist: ${pattern.completedChecklistCount}/10 completed ($percentInt%)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            onPressed: () => context.push('/patterns/${pattern.id}'),
          ),
        ],
      ),
    );
  }
}
