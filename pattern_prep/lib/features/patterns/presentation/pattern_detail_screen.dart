import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../models/pattern_model.dart';

class PatternDetailScreen extends ConsumerStatefulWidget {
  const PatternDetailScreen({super.key, required this.patternId});
  final String patternId;

  @override
  ConsumerState<PatternDetailScreen> createState() => _PatternDetailScreenState();
}

class _PatternDetailScreenState extends ConsumerState<PatternDetailScreen> {
  int _selectedCodeTab = 0; // 0 = C++, 1 = Python
  bool _hideExplanationsAndCode = false;
  late final TextEditingController _notesController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _checklistKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmResetChecklist(String patternId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset Checklist Progress?'),
        content: const Text(
          'This will uncheck all 10 checklist items for this pattern. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(patternDetailsProvider.notifier).resetChecklist(patternId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checklist reset.')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _scrollToChecklist() {
    Scrollable.ensureVisible(
      _checklistKey.currentContext ?? context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(patternDetailsProvider);
    final detail = details.where((d) => d.id == widget.patternId).firstOrNull;

    if (detail == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Pattern Detail')),
        body: const Center(child: Text('Pattern not found')),
      );
    }

    if (_notesController.text.isEmpty && detail.personalNotes.isNotEmpty) {
      _notesController.text = detail.personalNotes;
    }

    final checklist = detail.checklist;
    final primaryTemplate = detail.codeTemplates.isNotEmpty ? detail.codeTemplates.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                tooltip: _hideExplanationsAndCode ? 'Reveal Content' : 'Hide for Recall Practice',
                icon: Icon(
                  _hideExplanationsAndCode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: _hideExplanationsAndCode ? AppColors.warning : AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _hideExplanationsAndCode = !_hideExplanationsAndCode),
              ),
              IconButton(
                tooltip: detail.isBookmarked ? 'Remove Bookmark' : 'Bookmark Pattern',
                icon: Icon(
                  detail.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: detail.isBookmarked ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () =>
                    ref.read(patternDetailsProvider.notifier).toggleBookmark(detail.id),
              ),
              IconButton(
                tooltip: 'Revision History',
                icon: const Icon(Icons.history_rounded, color: AppColors.accentBlue),
                onPressed: () => context.push('/progress/history'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                detail.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Top Header Controls & Status ─────────────────────────
                Row(
                  children: [
                    CategoryChip(label: detail.category),
                    const SizedBox(width: 8),
                    _StatusDropdown(
                      currentStatus: detail.status,
                      onChanged: (newStatus) {
                        ref.read(patternDetailsProvider.notifier).updateStatus(detail.id, newStatus);
                      },
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _scrollToChecklist,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.checklist_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${checklist.completedCount}/10',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Revise in 2 Minutes Banner Action ────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(40),
                        AppColors.accent.withAlpha(30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revise in 2 Minutes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Fast recall mode: intuition, clues, steps & code.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/patterns/${detail.id}/quick-review'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─────────────────────────────────────────────────────────
                // 1. Quick Idea (10-20 sec read)
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 1,
                  title: 'Quick Idea',
                  icon: Icons.lightbulb_outline_rounded,
                  color: AppColors.primary,
                  child: Text(
                    detail.quickIdea,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 2. When to Use
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 2,
                  title: 'When to Use',
                  icon: Icons.help_outline_rounded,
                  color: AppColors.secondary,
                  isBlurred: _hideExplanationsAndCode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.whenToUse.map((item) => _BulletPoint(text: item)).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 3. Recognition Clues
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 3,
                  title: 'Recognition Clues',
                  icon: Icons.search_rounded,
                  color: AppColors.accent,
                  isBlurred: _hideExplanationsAndCode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.recognitionClues.map((item) => _BulletPoint(text: item, icon: '🎯')).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 4. How It Works
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 4,
                  title: 'How It Works',
                  icon: Icons.psychology_outlined,
                  color: AppColors.info,
                  isBlurred: _hideExplanationsAndCode,
                  child: Text(
                    detail.howItWorks,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 5. Pattern Variations
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 5,
                  title: 'Pattern Variations',
                  icon: Icons.alt_route_rounded,
                  color: AppColors.primaryLight,
                  isBlurred: _hideExplanationsAndCode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.variations.map((item) => _BulletPoint(text: item, icon: '🔹')).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 6. Algorithm Steps
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 6,
                  title: 'Algorithm Steps',
                  icon: Icons.format_list_numbered_rounded,
                  color: AppColors.accent,
                  isBlurred: _hideExplanationsAndCode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.algorithmSteps.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 7. Complexity
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 7,
                  title: 'Complexity',
                  icon: Icons.speed_rounded,
                  color: AppColors.info,
                  isBlurred: _hideExplanationsAndCode,
                  child: Row(
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
                              const Text('TIME COMPLEXITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(detail.timeComplexity, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
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
                              const Text('SPACE COMPLEXITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(detail.spaceComplexity, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 8 & 9. C++ and Python Templates
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 8,
                  title: 'Code Templates (C++17 & Python 3)',
                  icon: Icons.code_rounded,
                  color: AppColors.success,
                  isBlurred: _hideExplanationsAndCode,
                  trailing: Row(
                    children: [
                      _LangChip(
                        label: 'C++',
                        isSelected: _selectedCodeTab == 0,
                        onTap: () => setState(() => _selectedCodeTab = 0),
                      ),
                      const SizedBox(width: 6),
                      _LangChip(
                        label: 'Python',
                        isSelected: _selectedCodeTab == 1,
                        onTap: () => setState(() => _selectedCodeTab = 1),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copy Code',
                        onPressed: () {
                          if (primaryTemplate != null) {
                            final code = _selectedCodeTab == 0
                                ? primaryTemplate.cppCode
                                : primaryTemplate.pythonCode;
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Template copied to clipboard!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  child: primaryTemplate == null
                      ? const Text('Template coming soon.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (primaryTemplate.description != null) ...[
                              Text(
                                primaryTemplate.description!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 8),
                            ],
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: HighlightView(
                                _selectedCodeTab == 0
                                    ? primaryTemplate.cppCode
                                    : primaryTemplate.pythonCode,
                                language: _selectedCodeTab == 0 ? 'cpp' : 'python',
                                theme: atomOneDarkTheme,
                                padding: const EdgeInsets.all(12),
                                textStyle: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 10. Common Mistakes
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 10,
                  title: 'Common Mistakes',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  isBlurred: _hideExplanationsAndCode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.commonMistakes.map((m) => _BulletPoint(text: m, icon: '⚠️')).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 11. Edge Cases
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 11,
                  title: 'Edge Cases',
                  icon: Icons.rule_rounded,
                  color: AppColors.error,
                  isBlurred: _hideExplanationsAndCode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.edgeCases.map((e) => _BulletPoint(text: e, icon: '⚡')).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 12. Related Patterns
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 12,
                  title: 'Related Patterns',
                  icon: Icons.hub_outlined,
                  color: AppColors.secondary,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: detail.relatedPatterns.map((relId) {
                      final relPattern = details.where((d) => d.id == relId).firstOrNull;
                      final name = relPattern != null ? relPattern.name : relId.replaceAll('_', ' ');
                      return ActionChip(
                        label: Text(name),
                        avatar: const Icon(Icons.arrow_forward_rounded, size: 14),
                        onPressed: () {
                          if (relPattern != null) {
                            context.push('/patterns/${relPattern.id}');
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 13. Revision Checklist
                // ─────────────────────────────────────────────────────────
                Container(
                  key: _checklistKey,
                  child: _SectionCard(
                    number: 13,
                    title: 'Revision Checklist',
                    icon: Icons.checklist_rounded,
                    color: AppColors.primary,
                    trailing: Row(
                      children: [
                        Text(
                          '${checklist.completedCount}/${checklist.totalCount} (${(checklist.completionPercentage * 100).toInt()}%)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Reset Checklist',
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          onPressed: () => _confirmResetChecklist(detail.id),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: checklist.completionPercentage,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...checklist.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              onTap: () {
                                ref.read(patternDetailsProvider.notifier).toggleChecklistItem(detail.id, item.id);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                      size: 20,
                                      color: item.isCompleted ? AppColors.success : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: item.isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (checklist.nextIncompleteItem != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Complete next item
                                    final next = checklist.nextIncompleteItem!;
                                    ref.read(patternDetailsProvider.notifier).toggleChecklistItem(detail.id, next.id);
                                  },
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: const Text('Check Next Item'),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(patternDetailsProvider.notifier).markReviewed(detail.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked pattern as reviewed!'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.done_all_rounded, size: 16),
                                label: const Text('Mark Reviewed'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ─────────────────────────────────────────────────────────
                // 14. Personal Notes
                // ─────────────────────────────────────────────────────────
                _SectionCard(
                  number: 14,
                  title: 'Personal Notes',
                  icon: Icons.edit_note_rounded,
                  color: AppColors.accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Add personal insights, custom variations, or reminder notes here...',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(patternDetailsProvider.notifier).savePersonalNotes(detail.id, _notesController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Personal notes saved locally!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Save Notes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.trailing,
    this.isBlurred = false,
  });

  final int number;
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final Widget? trailing;
  final bool isBlurred;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          if (isBlurred)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Text(
                    'Hidden for active recall • Toggle Reveal in app bar',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, this.icon});
  final String text;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon ?? '•', style: const TextStyle(fontSize: 14, color: AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.currentStatus, required this.onChanged});
  final LearningStatus currentStatus;
  final ValueChanged<LearningStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LearningStatus>(
      initialValue: currentStatus,
      onSelected: onChanged,
      color: AppColors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(status: currentStatus),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (ctx) => LearningStatus.values.map((s) {
        return PopupMenuItem(
          value: s,
          child: StatusBadge(status: s),
        );
      }).toList(),
    );
  }
}
