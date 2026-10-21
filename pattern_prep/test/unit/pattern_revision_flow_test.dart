import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pattern_prep/core/providers/app_providers.dart';
import 'package:pattern_prep/features/patterns/models/pattern_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Checklist Persistence Flow (Simulated Restart)', () {
    test('Checklist changes persist into SharedPreferences and survive container reload', () async {
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);

      const patternId = 'two_pointers';

      // 1. Check 3 items in container 1
      await container1.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'idea');
      await container1.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'when_to_use');
      await container1.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'clues');

      // 2. Set status to learning
      await container1.read(patternDetailsProvider.notifier).updateStatus(patternId, LearningStatus.learning);

      // 3. Bookmark pattern
      await container1.read(patternDetailsProvider.notifier).toggleBookmark(patternId);

      // 4. Save personal notes
      await container1.read(patternDetailsProvider.notifier).savePersonalNotes(patternId, 'Remember left < right');

      // Verify in container 1
      final p1 = container1.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(p1.checklist.completedCount, equals(3));
      expect(p1.checklistPercentage, equals(0.3));
      expect(p1.status, equals(LearningStatus.learning));
      expect(p1.isBookmarked, isTrue);
      expect(p1.personalNotes, equals('Remember left < right'));

      // 5. Simulate App Restart: Create container 2 with the same shared preferences
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      // Await container 2 state restoration from SharedPreferences
      await container2.read(patternDetailsProvider.notifier).loadPersistedState();

      final p2 = container2.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(p2.checklist.completedCount, equals(3));
      expect(p2.checklistPercentage, equals(0.3));
      expect(p2.status, equals(LearningStatus.learning));
      expect(p2.isBookmarked, isTrue);
      expect(p2.personalNotes, equals('Remember left < right'));
    });
  });

  group('Spaced Repetition & Confidence Flow', () {
    test('Rating confidence Again sets status to needsRevision and updates review count', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'monotonic_stack';
      container.read(patternDetailsProvider.notifier).recordRevision(
        patternId: patternId,
        confidence: RevisionConfidence.again,
        notes: 'Need to practice next greater element on circular arrays',
      );

      final detail = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(detail.status, equals(LearningStatus.needsRevision));
      expect(detail.lastReviewedAt, isNotNull);

      // Check stats reflect needsRevisionCount
      final stats = container.read(revisionStatsProvider);
      expect(stats.needsRevisionCount, greaterThanOrEqualTo(1));
    });

    test('Rating confidence Easy marks pattern reviewed', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'prefix_sum';
      container.read(patternDetailsProvider.notifier).recordRevision(
        patternId: patternId,
        confidence: RevisionConfidence.easy,
      );

      final detail = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(detail.status, equals(LearningStatus.reviewed));
    });
  });

  group('Progress Dashboard Calculations', () {
    test('Distinguishes checklist completion, review completion, and mastery', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Master one pattern deliberately
      container.read(patternDetailsProvider.notifier).updateStatus('two_pointers', LearningStatus.mastered);

      // Review another pattern
      container.read(patternDetailsProvider.notifier).updateStatus('binary_search', LearningStatus.reviewed);

      final stats = container.read(revisionStatsProvider);
      expect(stats.masteredCount, equals(1));
      expect(stats.reviewedCount, equals(1));
      expect(stats.notStartedCount, equals(stats.totalPatterns - 2));
    });
  });
}
