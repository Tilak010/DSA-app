import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/shared_widgets.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(bookmarkedPatternsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Bookmarks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookmarked.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'No bookmarks yet',
              subtitle: 'Bookmark patterns from the Patterns screen to see them here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: bookmarked.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = bookmarked[i];
                return AppCard(
                  onTap: () => context.push('/patterns/${p.id}'),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.code_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p.shortDescription,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                CategoryChip(label: p.category, compact: true),
                                const SizedBox(width: 6),
                                StatusBadge(status: p.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            ref.read(patternsProvider.notifier).toggleBookmark(p.id),
                        icon: const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 20),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
