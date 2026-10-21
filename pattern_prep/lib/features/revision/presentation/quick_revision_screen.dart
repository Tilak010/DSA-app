import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../patterns/models/pattern_model.dart';
import '../models/revision_task_model.dart';

class QuickRevisionScreen extends ConsumerStatefulWidget {
  const QuickRevisionScreen({super.key, required this.patternId});
  final String patternId;

  @override
  ConsumerState<QuickRevisionScreen> createState() => _QuickRevisionScreenState();
}

class _QuickRevisionScreenState extends ConsumerState<QuickRevisionScreen> {
  int _currentStep = 1; // 1 to 6
  RevisionConfidence? _selectedConfidence;
  bool _isSaving = false;
  bool _hasSavedReview = false;
  double? _initialChecklistPercent;
  DateTime? _computedNextReviewDate;

  // Reveal toggles for Step 3
  final Map<String, bool> _revealedSections = {
    'idea': false,
    'clues': false,
    'steps': false,
    'complexity': false,
    'cpp': false,
    'python': false,
    'mistakes': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pattern = ref.read(patternDetailsProvider.notifier).getById(widget.patternId);
      if (pattern != null) {
        setState(() {
          _initialChecklistPercent = pattern.checklistPercentage;
        });
      }
    });
  }

  void _toggleReveal(String sectionKey) {
    setState(() {
      _revealedSections[sectionKey] = !(_revealedSections[sectionKey] ?? false);
    });
  }

  void _revealAll(bool reveal) {
    setState(() {
      for (final key in _revealedSections.keys) {
        _revealedSections[key] = reveal;
      }
    });
  }

  Future<void> _submitConfidence(PatternDetail pattern, RevisionConfidence confidence) async {
    if (_isSaving || _hasSavedReview) return;
    setState(() {
      _isSaving = true;
      _selectedConfidence = confidence;
    });

    final srs = ref.read(spacedRepetitionServiceProvider);
    final prefs = ref.read(revisionPreferencesProvider);
    final now = DateTime.now();
    final nextDate = srs.calculateNextReviewDate(now, confidence, preferences: prefs);

    // Persist review session & checklist completion through repository layer
    await ref.read(patternDetailsProvider.notifier).recordRevision(
      patternId: pattern.id,
      confidence: confidence,
      nextReviewDate: nextDate,
      checklistCompletion: pattern.checklistPercentage,
      isCompleted: true,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasSavedReview = true;
        _computedNextReviewDate = nextDate;
        _currentStep = 6; // Move to summary
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pattern = ref.watch(patternDetailsProvider.notifier).getById(widget.patternId);

    if (pattern == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pattern Revision')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Pattern not found', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    _initialChecklistPercent ??= pattern.checklistPercentage;

    return PopScope(
      canPop: _hasSavedReview || _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Leave Revision Session?'),
            content: const Text(
              'Your checklist updates have been saved, but the review session will not be recorded as complete and the schedule will not advance.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Leave Session'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            pattern.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Step $_currentStep of 6',
                style: const TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close Session',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: _currentStep / 6.0,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              minHeight: 4,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildStepHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildStepContent(pattern),
              ),
            ),
            _buildNavigationBottomBar(pattern),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    String stepTitle = '';
    String stepSubtitle = '';

    switch (_currentStep) {
      case 1:
        stepTitle = 'Step 1: Introduction';
        stepSubtitle = 'Review pattern overview, category, and current progress.';
        break;
      case 2:
        stepTitle = 'Step 2: Quick Recall';
        stepSubtitle = 'Test your recall before revealing the answers.';
        break;
      case 3:
        stepTitle = 'Step 3: Reveal Answers';
        stepSubtitle = 'Reveal each component to verify your mental model.';
        break;
      case 4:
        stepTitle = 'Step 4: Checklist';
        stepSubtitle = 'Update your 10-point mastery checklist.';
        break;
      case 5:
        stepTitle = 'Step 5: Confidence Rating';
        stepSubtitle = 'Rate how comfortably you recalled this pattern to schedule next review.';
        break;
      case 6:
        stepTitle = 'Step 6: Session Summary';
        stepSubtitle = 'Revision completed! Next review date scheduled.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stepSubtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(PatternDetail pattern) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Intro(pattern);
      case 2:
        return _buildStep2Recall(pattern);
      case 3:
        return _buildStep3Reveal(pattern);
      case 4:
        return _buildStep4Checklist(pattern);
      case 5:
        return _buildStep5Rating(pattern);
      case 6:
        return _buildStep6Summary(pattern);
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 1: INTRODUCTION
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStep1Intro(PatternDetail pattern) {
    final srs = ref.watch(spacedRepetitionServiceProvider);
    final due = srs.classifyDueTiming(pattern.nextReviewDate, pattern.status, pattern.lastReviewedAt);
    final completionPct = (pattern.checklistPercentage * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pattern.category,
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildStatusChip(pattern.status, due),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  pattern.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pattern.quickIdea,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 28, color: AppColors.cardBorder),
                Row(
                  children: [
                    Expanded(
                      child: _buildIntroStatItem(
                        icon: Icons.checklist,
                        label: 'Checklist Progress',
                        value: '$completionPct% (${pattern.checklistCompletedIds.length}/10)',
                        color: AppColors.accentBlue,
                      ),
                    ),
                    Expanded(
                      child: _buildIntroStatItem(
                        icon: Icons.history,
                        label: 'Last Reviewed',
                        value: pattern.lastReviewedAt != null
                            ? '${pattern.lastReviewedAt!.day}/${pattern.lastReviewedAt!.month}/${pattern.lastReviewedAt!.year}'
                            : 'Never',
                        color: AppColors.accentEmerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildIntroStatItem(
                        icon: Icons.star_outline,
                        label: 'Last Rating',
                        value: pattern.lastConfidence?.label ?? 'None yet',
                        color: AppColors.accentAmber,
                      ),
                    ),
                    Expanded(
                      child: _buildIntroStatItem(
                        icon: Icons.repeat,
                        label: 'Consecutive',
                        value: '${pattern.consecutiveReviews} times',
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.accentBlue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This revision session tests your recall across the pattern\'s algorithm, recognition clues, complexity, and templates, followed by confidence rating to schedule your next review.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 2: QUICK RECALL
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStep2Recall(PatternDetail pattern) {
    final recallPrompts = [
      {'icon': Icons.psychology, 'q': 'Explain the pattern in your own words.', 'hint': 'What is the core intuition and what invariant does it maintain?'},
      {'icon': Icons.search, 'q': 'What clues indicate this pattern in a problem?', 'hint': 'Think about keyword triggers, input constraints, and problem types.'},
      {'icon': Icons.format_list_numbered, 'q': 'What are the main algorithm steps?', 'hint': 'Trace the pointers, state updates, and boundary conditions.'},
      {'icon': Icons.speed, 'q': 'What are its time and space complexities?', 'hint': 'Account for auxiliary memory, recursion stack, and iteration.'},
      {'icon': Icons.code, 'q': 'Can you mentally write the C++ or Python template?', 'hint': 'Recall the standard while/for loop structure and initialization.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Recall Challenge',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Before revealing answers in Step 3, try answering these questions mentally or aloud.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...recallPrompts.map((item) => Card(
              color: AppColors.card,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accentBlue.withValues(alpha: 0.15),
                      child: Icon(item['icon'] as IconData, size: 18, color: AppColors.accentBlue),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['q'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['hint'] as String,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 3: REVEAL ANSWERS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStep3Reveal(PatternDetail pattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Verify Your Recall',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _revealAll(true),
                  child: const Text('Reveal All', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => _revealAll(false),
                  child: const Text('Hide All', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1. Core Idea
        _buildCollapsibleSection(
          title: 'Core Idea & Intuition',
          key: 'idea',
          icon: Icons.lightbulb,
          content: Text(
            pattern.quickIdea,
            style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
          ),
        ),

        // 2. Recognition Clues
        _buildCollapsibleSection(
          title: 'Recognition Clues',
          key: 'clues',
          icon: Icons.search,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pattern.recognitionClues.map((clue) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(clue, style: const TextStyle(color: Colors.white, fontSize: 13))),
                ],
              ),
            )).toList(),
          ),
        ),

        // 3. Algorithm Steps
        _buildCollapsibleSection(
          title: 'Algorithm Steps',
          key: 'steps',
          icon: Icons.format_list_numbered,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pattern.algorithmSteps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
                ],
              ),
            )).toList(),
          ),
        ),

        // 4. Complexity
        _buildCollapsibleSection(
          title: 'Time & Space Complexity',
          key: 'complexity',
          icon: Icons.speed,
          content: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time Complexity', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(pattern.timeComplexity, style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Space Complexity', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(pattern.spaceComplexity, style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 5. C++ Code Template
        _buildCollapsibleSection(
          title: 'C++ Template',
          key: 'cpp',
          icon: Icons.code,
          content: _buildCodeBlock(pattern, 'cpp'),
        ),

        // 6. Python Code Template
        _buildCollapsibleSection(
          title: 'Python Template',
          key: 'python',
          icon: Icons.terminal,
          content: _buildCodeBlock(pattern, 'python'),
        ),

        // 7. Common Mistakes
        _buildCollapsibleSection(
          title: 'Common Mistakes & Pitfalls',
          key: 'mistakes',
          icon: Icons.warning_amber_rounded,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pattern.commonMistakes.map((mistake) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(child: Text(mistake, style: const TextStyle(color: Colors.white, fontSize: 13))),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required String key,
    required IconData icon,
    required Widget content,
  }) {
    final isRevealed = _revealedSections[key] ?? false;

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRevealed ? AppColors.accentBlue.withValues(alpha: 0.3) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleReveal(key),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: isRevealed ? AppColors.accentBlue : AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isRevealed ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    isRevealed ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: isRevealed ? AppColors.accentBlue : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRevealed ? 'Hide' : 'Reveal',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRevealed ? AppColors.accentBlue : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isRevealed) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: content,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeBlock(PatternDetail pattern, String lang) {
    final template = pattern.codeTemplates.isNotEmpty ? pattern.codeTemplates.first : null;
    final code = template != null
        ? (lang == 'cpp' ? template.cppCode : template.pythonCode)
        : '// No code template available';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.toUpperCase(),
                style: const TextStyle(color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                tooltip: 'Copy Code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
          HighlightView(
            code,
            language: lang == 'cpp' ? 'cpp' : 'python',
            theme: atomOneDarkTheme,
            padding: const EdgeInsets.all(8),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 4: CHECKLIST
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStep4Checklist(PatternDetail pattern) {
    final checklist = pattern.checklist;
    final completedCount = checklist.completedCount;
    final totalCount = checklist.totalCount;
    final percent = (checklist.completionPercentage * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Revision Checklist',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completedCount / $totalCount ($percent%)',
                style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Mark what you verified during this session. Changes persist immediately.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: checklist.completionPercentage,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              checklist.completionPercentage == 1.0 ? AppColors.accentEmerald : AppColors.accentBlue,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        ...checklist.items.map((item) => Card(
              color: AppColors.card,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: item.isCompleted ? AppColors.accentEmerald.withValues(alpha: 0.3) : AppColors.cardBorder,
                ),
              ),
              child: CheckboxListTile(
                value: item.isCompleted,
                onChanged: (val) {
                  ref.read(patternDetailsProvider.notifier).toggleChecklistItem(pattern.id, item.id);
                },
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: item.isCompleted ? Colors.white : AppColors.textSecondary,
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                activeColor: AppColors.accentEmerald,
                checkColor: Colors.black,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              ),
            )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 5: CONFIDENCE RATING
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStep5Rating(PatternDetail pattern) {
    final prefs = ref.watch(revisionPreferencesProvider);

    final ratings = [
      {
        'rating': RevisionConfidence.again,
        'title': 'Again',
        'interval': '${prefs.againIntervalDays} day',
        'desc': 'Difficult to recall. Schedule for tomorrow.',
        'color': AppColors.error,
        'icon': Icons.replay,
      },
      {
        'rating': RevisionConfidence.hard,
        'title': 'Hard',
        'interval': '${prefs.hardIntervalDays} days',
        'desc': 'Remembered some parts but needed substantial help.',
        'color': AppColors.accentAmber,
        'icon': Icons.sentiment_neutral,
      },
      {
        'rating': RevisionConfidence.good,
        'title': 'Good',
        'interval': '${prefs.goodIntervalDays} days',
        'desc': 'Recalled most of the material independently.',
        'color': AppColors.accentBlue,
        'icon': Icons.sentiment_satisfied,
      },
      {
        'rating': RevisionConfidence.easy,
        'title': 'Easy',
        'interval': '${prefs.easyIntervalDays} days',
        'desc': 'Recalled confidently without needing answer reveals.',
        'color': AppColors.accentEmerald,
        'icon': Icons.sentiment_very_satisfied,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How confident do you feel?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your recall confidence to deterministically schedule your next revision.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        ...ratings.map((item) {
          final rating = item['rating'] as RevisionConfidence;
          final color = item['color'] as Color;
          final isSelected = _selectedConfidence == rating;

          return Card(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.card,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? color : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: _isSaving ? null : () => _submitConfidence(pattern, rating),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Icon(item['icon'] as IconData, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${item['interval']}',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc'] as String,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isSaving && isSelected)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.arrow_forward_ios, size: 14, color: isSelected ? color : AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 6: SESSION SUMMARY
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStep6Summary(PatternDetail pattern) {
    final beforePct = ((_initialChecklistPercent ?? 0.0) * 100).toInt();
    final afterPct = (pattern.checklistPercentage * 100).toInt();
    final prevDate = pattern.lastReviewedAt != null
        ? '${pattern.lastReviewedAt!.day}/${pattern.lastReviewedAt!.month}/${pattern.lastReviewedAt!.year}'
        : 'Never';
    final nextDateStr = _computedNextReviewDate != null
        ? '${_computedNextReviewDate!.day}/${_computedNextReviewDate!.month}/${_computedNextReviewDate!.year}'
        : 'Tomorrow';

    // Look up next pattern in daily queue
    final dailyQueue = ref.watch(dailyQueueProvider);
    final nextPattern = dailyQueue.where((p) => p.id != pattern.id).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.accentEmerald.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.accentEmerald, size: 48),
              const SizedBox(height: 10),
              const Text(
                'Revision Session Completed!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Progress saved and next review scheduled for $nextDateStr.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Session Breakdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 20, color: AppColors.cardBorder),
                _buildSummaryRow('Pattern', pattern.name),
                _buildSummaryRow('Category', pattern.category),
                _buildSummaryRow('Confidence Rating', _selectedConfidence?.label ?? 'Good'),
                _buildSummaryRow('Checklist Progress', '$beforePct% → $afterPct%'),
                _buildSummaryRow('Previous Review Date', prevDate),
                _buildSummaryRow('Next Review Date', nextDateStr),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (nextPattern != null) ...[
          ElevatedButton.icon(
            onPressed: () {
              context.pushReplacement('/patterns/${nextPattern.id}/quick-review');
            },
            icon: const Icon(Icons.skip_next),
            label: Text('Continue to Next: ${nextPattern.name}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.cardBorder),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Finish Session & Return to Planner'),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNavigationBottomBar(PatternDetail pattern) {
    // Hide bottom bar in Step 6 (handled within summary) and Step 5 (ratings tap to submit)
    if (_currentStep == 6 || _currentStep == 5) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 1)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.cardBorder),
              ),
            )
          else
            const SizedBox(),
          ElevatedButton.icon(
            onPressed: () => setState(() => _currentStep++),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(_currentStep == 4 ? 'Proceed to Rating' : 'Next Step'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(LearningStatus status, RevisionDue due) {
    Color color = AppColors.accentBlue;
    String label = 'Upcoming';

    switch (due) {
      case RevisionDue.overdue:
        color = AppColors.error;
        label = 'Overdue';
        break;
      case RevisionDue.today:
        color = AppColors.accentAmber;
        label = 'Due Today';
        break;
      case RevisionDue.recentlyReviewed:
        color = AppColors.accentEmerald;
        label = 'Recent';
        break;
      case RevisionDue.upcoming:
        color = AppColors.accentBlue;
        label = 'Upcoming';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildIntroStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
