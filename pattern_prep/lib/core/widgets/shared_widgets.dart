import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../features/patterns/models/pattern_model.dart';
import '../../features/problems/models/problem_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty Badge
// ─────────────────────────────────────────────────────────────────────────────

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case Difficulty.easy:
        color = AppColors.diffEasy;
        break;
      case Difficulty.medium:
        color = AppColors.diffMedium;
        break;
      case Difficulty.hard:
        color = AppColors.diffHard;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge (for learning status)
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final LearningStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case LearningStatus.notStarted:
        color = AppColors.textMuted;
        icon = Icons.circle_outlined;
        break;
      case LearningStatus.learning:
        color = AppColors.warning;
        icon = Icons.auto_stories_outlined;
        break;
      case LearningStatus.needsRevision:
        color = AppColors.error;
        icon = Icons.refresh_rounded;
        break;
      case LearningStatus.reviewed:
        color = AppColors.secondary;
        icon = Icons.check_circle_outline_rounded;
        break;
      case LearningStatus.mastered:
        color = AppColors.success;
        icon = Icons.verified_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Chip
// ─────────────────────────────────────────────────────────────────────────────

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, this.compact = false});
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withAlpha(50), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w500,
          color: AppColors.chipText,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.actionLabel,
  });

  final String title;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel ?? 'See All',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Bar with label
// ─────────────────────────────────────────────────────────────────────────────

class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.value,
    this.label,
    this.height = 6,
    this.showPercent = true,
  });

  final double value;
  final String? label;
  final double height;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercent)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (showPercent)
                  Text(
                    '${(value * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App surface card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 16.0,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.primary.withAlpha(20),
        highlightColor: AppColors.primary.withAlpha(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: action,
                child: Text(actionLabel ?? 'Get Started'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
