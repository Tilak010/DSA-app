import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../patterns/models/pattern_model.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(revisionStatsProvider);
    final avgChecklistPercentInt = (stats.avgChecklistCompletion * 100).toInt();
    final masteryPercent = stats.totalPatterns > 0
        ? (stats.masteredCount / stats.totalPatterns)
        : 0.0;
    final reviewedPercent = stats.totalPatterns > 0
        ? (stats.reviewedCount / stats.totalPatterns)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Revision Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.accentBlue),
            tooltip: 'View Revision History',
            onPressed: () => context.push('/progress/history'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Overall Revision Metrics Card ────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Overall Pattern Progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BigStat(
                      value: '${stats.totalPatterns}',
                      label: 'Total Patterns',
                      color: AppColors.primary,
                      icon: Icons.grid_view_rounded,
                    ),
                    _BigStat(
                      value: '${stats.masteredCount}',
                      label: 'Mastered',
                      color: AppColors.success,
                      icon: Icons.verified_rounded,
                    ),
                    _BigStat(
                      value: '${stats.reviewedCount}',
                      label: 'Reviewed',
                      color: AppColors.secondary,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _BigStat(
                      value: '$avgChecklistPercentInt%',
                      label: 'Avg Checklist',
                      color: AppColors.accent,
                      icon: Icons.checklist_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LabeledProgressBar(
                  value: masteryPercent,
                  label: 'Pattern Mastery (${stats.masteredCount}/${stats.totalPatterns})',
                  showPercent: true,
                  height: 8,
                ),
                const SizedBox(height: 8),
                LabeledProgressBar(
                  value: reviewedPercent,
                  label: 'Patterns Reviewed (${stats.reviewedCount}/${stats.totalPatterns})',
                  showPercent: true,
                  height: 6,
                ),
                const SizedBox(height: 8),
                LabeledProgressBar(
                  value: stats.avgChecklistCompletion,
                  label: 'Average Checklist Completion',
                  showPercent: true,
                  height: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Three-Tier Progress Definition Guide ─────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distinction Between Progress Levels:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                SizedBox(height: 6),
                Text('• Checklist Completion: Items checked (intuition, clues, algorithm, templates).', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('• Review Completion: Pattern reviewed in a session and confidence rated.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('• Mastery: Deliberate status indicating you can implement without hints.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Status Breakdown ─────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pattern Status Breakdown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  status: LearningStatus.mastered,
                  count: stats.masteredCount,
                  total: stats.totalPatterns,
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  status: LearningStatus.reviewed,
                  count: stats.reviewedCount,
                  total: stats.totalPatterns,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  status: LearningStatus.learning,
                  count: stats.learningCount,
                  total: stats.totalPatterns,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  status: LearningStatus.needsRevision,
                  count: stats.needsRevisionCount,
                  total: stats.totalPatterns,
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  status: LearningStatus.notStarted,
                  count: stats.notStartedCount,
                  total: stats.totalPatterns,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Spaced Repetition Activity ───────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revision Activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SESSIONS COMPLETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Text('${stats.revisionSessionsCompleted}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('REVISE THIS WEEK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Text('${stats.reviewedThisWeekCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Category Progress Breakdown ──────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress by Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...stats.categoryProgress.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${(entry.value * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value,
                            minHeight: 5,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Weakest Patterns ─────────────────────────────────────────────
          if (stats.weakestPatterns.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text(
                        'Weakest Patterns (Prioritize)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...stats.weakestPatterns.map((p) {
                    final percentInt = (p.checklistPercentage * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${p.category} • Checklist: $percentInt%',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: p.status),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.primary),
                            tooltip: 'Quick Review',
                            onPressed: () => context.push('/patterns/${p.id}/quick-review'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.count,
    required this.total,
    required this.color,
  });

  final LearningStatus status;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final frac = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        SizedBox(width: 100, child: StatusBadge(status: status)),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
