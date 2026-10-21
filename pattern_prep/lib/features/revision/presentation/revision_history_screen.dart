import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../patterns/models/pattern_model.dart';

class RevisionHistoryScreen extends ConsumerStatefulWidget {
  const RevisionHistoryScreen({super.key});

  @override
  ConsumerState<RevisionHistoryScreen> createState() => _RevisionHistoryScreenState();
}

class _RevisionHistoryScreenState extends ConsumerState<RevisionHistoryScreen> {
  String _searchQuery = '';
  RevisionConfidence? _filterConfidence;

  Future<void> _confirmDelete(BuildContext context, PatternReviewRecord record, String patternName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Revision Entry?'),
        content: Text(
          'Are you sure you want to delete the revision record for "$patternName" from ${record.reviewedAt.day}/${record.reviewedAt.month}/${record.reviewedAt.year}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(patternDetailsProvider.notifier).deleteReviewRecord(record.id);
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Revision record deleted.'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(reviewHistoryProvider);
    final patternsNotifier = ref.watch(patternDetailsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Revision History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error loading history: $err', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        data: (records) {
          final filteredRecords = records.where((r) {
            final pattern = patternsNotifier.getById(r.patternId);
            final name = pattern?.name.toLowerCase() ?? r.patternId.toLowerCase();
            if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
              return false;
            }
            if (_filterConfidence != null && r.confidence != _filterConfidence) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: filteredRecords.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_toggle_off_rounded,
                                  size: 56, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                              const SizedBox(height: 16),
                              const Text(
                                'No Revision History Found',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Complete a pattern revision session to build your spaced repetition audit trail.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          final pattern = patternsNotifier.getById(record.patternId);
                          final patternName = pattern?.name ?? record.patternId;
                          final category = pattern?.category ?? 'DSA';

                          return _buildHistoryCard(record, patternName, category);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by pattern name...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildConfidenceChip(null, 'All Ratings'),
                const SizedBox(width: 6),
                _buildConfidenceChip(RevisionConfidence.again, 'Again'),
                const SizedBox(width: 6),
                _buildConfidenceChip(RevisionConfidence.hard, 'Hard'),
                const SizedBox(width: 6),
                _buildConfidenceChip(RevisionConfidence.good, 'Good'),
                const SizedBox(width: 6),
                _buildConfidenceChip(RevisionConfidence.easy, 'Easy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(RevisionConfidence? confidence, String label) {
    final isSelected = _filterConfidence == confidence;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textSecondary)),
      selected: isSelected,
      selectedColor: AppColors.accentBlue,
      backgroundColor: AppColors.card,
      onSelected: (selected) {
        setState(() {
          _filterConfidence = selected ? confidence : null;
        });
      },
    );
  }

  Widget _buildHistoryCard(PatternReviewRecord record, String patternName, String category) {
    final dateStr =
        '${record.reviewedAt.day}/${record.reviewedAt.month}/${record.reviewedAt.year} at ${record.reviewedAt.hour.toString().padLeft(2, '0')}:${record.reviewedAt.minute.toString().padLeft(2, '0')}';
    final nextStr = record.nextReviewDate != null
        ? '${record.nextReviewDate!.day}/${record.nextReviewDate!.month}/${record.nextReviewDate!.year}'
        : 'Not assigned';
    final completionPct = (record.checklistCompletion * 100).toInt();

    Color ratingColor;
    switch (record.confidence) {
      case RevisionConfidence.again:
        ratingColor = AppColors.error;
        break;
      case RevisionConfidence.hard:
        ratingColor = AppColors.accentAmber;
        break;
      case RevisionConfidence.good:
        ratingColor = AppColors.accentBlue;
        break;
      case RevisionConfidence.easy:
        ratingColor = AppColors.accentEmerald;
        break;
    }

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: ratingColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          record.confidence.label,
                          style: TextStyle(
                            color: ratingColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Delete review record',
                  onPressed: () => _confirmDelete(context, record, patternName),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              patternName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Reviewed', dateStr, Icons.access_time),
                ),
                Expanded(
                  child: _buildDetailItem('Next Review', nextStr, Icons.event),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Checklist At Review',
                    '$completionPct%',
                    Icons.checklist,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Session Status',
                    record.isCompleted ? 'Completed' : 'Partial',
                    Icons.verified_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
