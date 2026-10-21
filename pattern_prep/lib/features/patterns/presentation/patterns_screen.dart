import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/patterns_data.dart';
import '../models/pattern_model.dart';

enum PatternSortOption {
  nameAsc,
  completionDesc,
  completionAsc,
  recentlyReviewed,
}

class PatternsScreen extends ConsumerStatefulWidget {
  const PatternsScreen({super.key});

  @override
  ConsumerState<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends ConsumerState<PatternsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  LearningStatus? _selectedStatus; // null = All
  bool _filterIncompleteChecklist = false;
  bool _filterNeedsRevision = false;
  bool _filterBookmarked = false;
  PatternSortOption _sortOption = PatternSortOption.nameAsc;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PatternSummary> _filterAndSort(List<PatternSummary> all) {
    var list = all.where((p) {
      // Search
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.quickIdea.toLowerCase().contains(query);

      // Category
      final matchesCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;

      // Status
      final matchesStatus =
          _selectedStatus == null || p.status == _selectedStatus;

      // Incomplete checklist filter
      final matchesIncomplete =
          !_filterIncompleteChecklist || p.checklistPercentage < 1.0;

      // Needs Revision filter
      final matchesNeedsRevision =
          !_filterNeedsRevision || p.status == LearningStatus.needsRevision;

      // Bookmarked filter
      final matchesBookmarked = !_filterBookmarked || p.isBookmarked;

      return matchesSearch &&
          matchesCat &&
          matchesStatus &&
          matchesIncomplete &&
          matchesNeedsRevision &&
          matchesBookmarked;
    }).toList();

    // Sorting
    switch (_sortOption) {
      case PatternSortOption.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PatternSortOption.completionDesc:
        list.sort((a, b) => b.checklistPercentage.compareTo(a.checklistPercentage));
        break;
      case PatternSortOption.completionAsc:
        list.sort((a, b) => a.checklistPercentage.compareTo(b.checklistPercentage));
        break;
      case PatternSortOption.recentlyReviewed:
        list.sort((a, b) {
          if (a.lastReviewedAt == null && b.lastReviewedAt == null) return 0;
          if (a.lastReviewedAt == null) return 1;
          if (b.lastReviewedAt == null) return -1;
          return b.lastReviewedAt!.compareTo(a.lastReviewedAt!);
        });
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final patterns = ref.watch(patternsProvider);
    final filtered = _filterAndSort(patterns);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('DSA Patterns Library'),
        actions: [
          IconButton(
            tooltip: 'View Bookmarks',
            icon: const Icon(Icons.bookmark_outline_rounded),
            onPressed: () => context.push('/bookmarks'),
          ),
          PopupMenuButton<PatternSortOption>(
            tooltip: 'Sort Patterns',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sortOption,
            onSelected: (opt) => setState(() => _sortOption = opt),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: PatternSortOption.nameAsc,
                child: Text('Name (A-Z)'),
              ),
              PopupMenuItem(
                value: PatternSortOption.completionDesc,
                child: Text('Checklist (Highest First)'),
              ),
              PopupMenuItem(
                value: PatternSortOption.completionAsc,
                child: Text('Checklist (Lowest First)'),
              ),
              PopupMenuItem(
                value: PatternSortOption.recentlyReviewed,
                child: Text('Recently Reviewed'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search patterns, ideas, or clues...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category Filter Bar ─────────────────────────────────────────
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kPatternCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = kPatternCategories[i];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Quick Filter Chips (Status, Incomplete, Needs Revision) ─────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Incomplete filter
                FilterChip(
                  label: const Text('Incomplete Checklist', style: TextStyle(fontSize: 11)),
                  selected: _filterIncompleteChecklist,
                  onSelected: (val) => setState(() => _filterIncompleteChecklist = val),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withAlpha(40),
                ),
                const SizedBox(width: 8),
                // Needs Revision filter
                FilterChip(
                  label: const Text('Needs Revision', style: TextStyle(fontSize: 11)),
                  selected: _filterNeedsRevision,
                  onSelected: (val) => setState(() => _filterNeedsRevision = val),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.error.withAlpha(40),
                ),
                const SizedBox(width: 8),
                // Bookmarked filter
                FilterChip(
                  label: const Text('Bookmarked', style: TextStyle(fontSize: 11)),
                  selected: _filterBookmarked,
                  onSelected: (val) => setState(() => _filterBookmarked = val),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent.withAlpha(40),
                ),
                const SizedBox(width: 8),
                // Status Popup
                PopupMenuButton<LearningStatus?>(
                  tooltip: 'Filter by Status',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedStatus != null ? AppColors.primary.withAlpha(30) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _selectedStatus != null ? AppColors.primary : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedStatus?.label ?? 'Status: All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selectedStatus != null ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  onSelected: (st) => setState(() => _selectedStatus = st),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: null, child: Text('All Statuses')),
                    ...LearningStatus.values.map(
                      (s) => PopupMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Patterns List ───────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No patterns found',
                    subtitle: 'Try adjusting your search terms or filter selection.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return _PatternCard(pattern: p);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends ConsumerWidget {
  const _PatternCard({required this.pattern});
  final PatternSummary pattern;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Never reviewed';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Reviewed today';
    if (diff.inDays == 1) return 'Reviewed yesterday';
    return 'Reviewed ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = pattern.checklistPercentage;
    final percentInt = (percent * 100).toInt();

    return AppCard(
      onTap: () => context.push('/patterns/${pattern.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, Category, Bookmark
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    CategoryChip(label: pattern.category, compact: true),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  pattern.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: pattern.isBookmarked ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => ref.read(patternsProvider.notifier).toggleBookmark(pattern.id),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: One-line Quick Idea
          Text(
            pattern.quickIdea,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Row 3: Checklist Progress Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Checklist Progress (${pattern.completedChecklistCount}/10)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          '$percentInt%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 5,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(
                          percent >= 1.0 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 4: Status, Last Reviewed, & Quick Review Action
          Row(
            children: [
              StatusBadge(status: pattern.status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(pattern.lastReviewedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/patterns/${pattern.id}/quick-review'),
                icon: const Icon(Icons.flash_on_rounded, size: 14),
                label: const Text('Quick Review', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
