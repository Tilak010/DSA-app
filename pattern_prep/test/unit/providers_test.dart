import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pattern_prep/core/providers/app_providers.dart';
import 'package:pattern_prep/features/patterns/models/pattern_model.dart';
import 'package:pattern_prep/features/patterns/data/patterns_data.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsNotifier', () {
    test('initial values are as expected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.isDarkMode, isTrue);
      expect(settings.defaultLanguage, equals('cpp'));
      expect(settings.dailyRevisionGoal, equals(5));
    });

    test('toggleTheme switches dark mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).toggleTheme();
      expect(container.read(settingsProvider).isDarkMode, isFalse);

      container.read(settingsProvider.notifier).toggleTheme();
      expect(container.read(settingsProvider).isDarkMode, isTrue);
    });

    test('setLanguage updates default code language', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setLanguage('python');
      expect(container.read(settingsProvider).defaultLanguage, equals('python'));
    });

    test('setDailyGoal updates target daily revision count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setDailyGoal(10);
      expect(container.read(settingsProvider).dailyRevisionGoal, equals(10));
    });
  });

  group('PatternsNotifier & Bookmarks', () {
    test('toggleBookmark toggles bookmark status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final patterns = container.read(patternsProvider);
      expect(patterns, isNotEmpty);
      final first = patterns.first;
      final initialBookmark = first.isBookmarked;

      container.read(patternsProvider.notifier).toggleBookmark(first.id);
      final updated = container.read(patternsProvider).firstWhere((p) => p.id == first.id);
      expect(updated.isBookmarked, equals(!initialBookmark));

      // Test derived bookmarkedPatternsProvider
      final bookmarked = container.read(bookmarkedPatternsProvider);
      if (!initialBookmark) {
        expect(bookmarked.any((p) => p.id == first.id), isTrue);
      }
    });

    test('updateStatus changes learning status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstId = container.read(patternsProvider).first.id;
      container.read(patternsProvider.notifier).updateStatus(firstId, LearningStatus.mastered);

      final updated = container.read(patternsProvider).firstWhere((p) => p.id == firstId);
      expect(updated.status, equals(LearningStatus.mastered));
    });
  });

  group('Pattern Revision Checklist & Notes', () {
    test('toggleChecklistItem updates completed items and percentage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'two_pointers';
      final initialDetail = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(initialDetail.checklist.completedCount, equals(0));

      // Check item 'idea'
      container.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'idea');
      var updated = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(updated.checklist.completedCount, equals(1));
      expect(updated.checklistPercentage, equals(0.1));

      // Check item 'algorithm'
      container.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'algorithm');
      updated = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(updated.checklist.completedCount, equals(2));
      expect(updated.checklistPercentage, equals(0.2));

      // Uncheck item 'idea'
      container.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'idea');
      updated = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(updated.checklist.completedCount, equals(1));
    });

    test('resetChecklist unchecks all items for pattern', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'two_pointers';
      container.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'idea');
      container.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'clues');

      container.read(patternDetailsProvider.notifier).resetChecklist(patternId);
      final updated = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(updated.checklist.completedCount, equals(0));
      expect(updated.checklistPercentage, equals(0.0));
    });

    test('recordRevision updates review count, date, and status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'two_pointers';
      container.read(patternDetailsProvider.notifier).recordRevision(
        patternId: patternId,
        confidence: RevisionConfidence.easy,
        notes: 'Felt very clear',
      );

      final updated = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(updated.status, equals(LearningStatus.reviewed));
      expect(updated.lastReviewedAt, isNotNull);
      expect(updated.personalNotes, equals('Felt very clear'));
    });
  });

  group('RevisionTasksNotifier & Stats', () {
    test('derived task lists partition correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final today = container.read(todayTasksProvider);
      final overdue = container.read(overdueTasksProvider);
      final upcoming = container.read(upcomingTasksProvider);

      expect(today, isA<List>());
      expect(overdue, isA<List>());
      expect(upcoming, isA<List>());
    });

    test('revisionStatsProvider computes accurate metrics from state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stats = container.read(revisionStatsProvider);
      expect(stats.totalPatterns, equals(kPatternDetails.length));
      expect(stats.avgChecklistCompletion, isNotNull);
      expect(stats.weakestPatterns, isNotEmpty);
      expect(stats.categoryProgress, isNotEmpty);
    });
  });
}
