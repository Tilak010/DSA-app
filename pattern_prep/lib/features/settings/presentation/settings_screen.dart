import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/shared_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmResetData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will reset all pattern checklist progress, review history, and bookmarks back to default. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(patternDetailsProvider.notifier).resetAll();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All revision progress has been reset.')),
                );
              }
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Appearance ───────────────────────────────────────────────────
          _SectionTitle(title: 'Appearance'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchTile(
                  icon: settings.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  iconColor: settings.isDarkMode ? AppColors.accent : AppColors.warning,
                  title: 'Dark Mode',
                  subtitle: settings.isDarkMode ? 'Using dark theme' : 'Using light theme',
                  value: settings.isDarkMode,
                  onChanged: (_) => notifier.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Code Language ────────────────────────────────────────────────
          _SectionTitle(title: 'Code Templates'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.code_rounded, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Default Language',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LangButton(
                      label: 'C++17',
                      icon: Icons.memory_rounded,
                      isSelected: settings.defaultLanguage == 'cpp',
                      onTap: () => notifier.setLanguage('cpp'),
                    ),
                    const SizedBox(width: 12),
                    _LangButton(
                      label: 'Python 3',
                      icon: Icons.auto_awesome_rounded,
                      isSelected: settings.defaultLanguage == 'python',
                      onTap: () => notifier.setLanguage('python'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Daily Goal ───────────────────────────────────────────────────
          _SectionTitle(title: 'Goals'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Daily Pattern Revision Goal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Text(
                        '${settings.dailyRevisionGoal} patterns',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Slider(
                  value: settings.dailyRevisionGoal.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${settings.dailyRevisionGoal}',
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceVariant,
                  onChanged: (v) => notifier.setDailyGoal(v.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('1 pattern', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('20 patterns', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          // ── Spaced Repetition Intervals ──────────────────────────────────
          _SectionTitle(title: 'Spaced Repetition Intervals'),
          Consumer(
            builder: (context, ref, child) {
              final prefs = ref.watch(revisionPreferencesProvider);
              final prefsNotifier = ref.read(revisionPreferencesProvider.notifier);

              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure default review intervals (in days) for each confidence rating:',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _IntervalSlider(
                      label: 'Again (Hard recall)',
                      value: prefs.againIntervalDays,
                      min: 1,
                      max: 5,
                      color: AppColors.error,
                      onChanged: (val) => prefsNotifier.updateIntervals(again: val),
                    ),
                    const SizedBox(height: 12),
                    _IntervalSlider(
                      label: 'Hard (Partial recall)',
                      value: prefs.hardIntervalDays,
                      min: 1,
                      max: 10,
                      color: AppColors.warning,
                      onChanged: (val) => prefsNotifier.updateIntervals(hard: val),
                    ),
                    const SizedBox(height: 12),
                    _IntervalSlider(
                      label: 'Good (Independent recall)',
                      value: prefs.goodIntervalDays,
                      min: 2,
                      max: 20,
                      color: AppColors.primary,
                      onChanged: (val) => prefsNotifier.updateIntervals(good: val),
                    ),
                    const SizedBox(height: 12),
                    _IntervalSlider(
                      label: 'Easy (Effortless recall)',
                      value: prefs.easyIntervalDays,
                      min: 4,
                      max: 45,
                      color: AppColors.success,
                      onChanged: (val) => prefsNotifier.updateIntervals(easy: val),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Revision Reminders ───────────────────────────────────────────
          _SectionTitle(title: 'Daily Reminders'),
          Consumer(
            builder: (context, ref, child) {
              final prefs = ref.watch(revisionPreferencesProvider);
              final prefsNotifier = ref.read(revisionPreferencesProvider.notifier);
              final notif = ref.watch(notificationServiceProvider);

              final timeStr =
                  '${prefs.reminderHour.toString().padLeft(2, '0')}:${prefs.reminderMinute.toString().padLeft(2, '0')}';

              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SwitchTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: AppColors.primary,
                      title: 'Daily Revision Reminder',
                      subtitle: prefs.reminderEnabled
                          ? 'Active at $timeStr'
                          : 'Disabled',
                      value: prefs.reminderEnabled,
                      onChanged: (enabled) async {
                        await prefsNotifier.setReminder(enabled: enabled);
                      },
                    ),
                    if (prefs.reminderEnabled) ...[
                      const Divider(height: 1, indent: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: prefs.reminderHour,
                              minute: prefs.reminderMinute,
                            ),
                          );
                          if (picked != null) {
                            await prefsNotifier.setReminder(
                              enabled: true,
                              hour: picked.hour,
                              minute: picked.minute,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 18, color: AppColors.textSecondary),
                                  SizedBox(width: 12),
                                  Text(
                                    'Reminder Time',
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            notif.isSupportedOnCurrentPlatform ? Icons.check_circle_outline : Icons.info_outline,
                            size: 14,
                            color: notif.isSupportedOnCurrentPlatform ? AppColors.success : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              notif.isSupportedOnCurrentPlatform
                                  ? 'Notifications configured cleanly for this device.'
                                  : 'Notification abstraction active (Desktop/Web mock support).',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Reset & Data ─────────────────────────────────────────────────
          _SectionTitle(title: 'Data & Storage'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.storage_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Persistence',
                  subtitle: 'Local device storage (SharedPreferences)',
                  trailing: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                ),
                const Divider(height: 1, indent: 16),
                InkWell(
                  onTap: () => context.push('/progress/history'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, color: AppColors.accentBlue, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Revision History Audit Trail',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              Text(
                                'Inspect ratings, review dates, and checklist states',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16),
                InkWell(
                  onTap: () => _confirmResetData(context, ref),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reset All Progress',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error),
                              ),
                              Text(
                                'Clear checklists, review history, and bookmarks',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── About ────────────────────────────────────────────────────────
          _SectionTitle(title: 'About'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: const [
                _InfoTile(
                  icon: Icons.psychology_rounded,
                  iconColor: AppColors.info,
                  title: 'PatternPrep',
                  subtitle: 'DSA Pattern Revision & Spaced Repetition',
                  trailing: Text('v2.0.0', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _IntervalSlider extends StatelessWidget {
  const _IntervalSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$value ${value == 1 ? 'day' : 'days'}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: color,
          inactiveColor: AppColors.surface,
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }
}
