import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pattern_prep/core/providers/app_providers.dart';
import 'package:pattern_prep/core/services/spaced_repetition_service.dart';
import 'package:pattern_prep/features/patterns/models/pattern_model.dart';
import 'package:pattern_prep/features/revision/models/revision_task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpacedRepetitionService srs;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    srs = const SpacedRepetitionService();
  });

  group('SpacedRepetitionService - Default Intervals & Configurable Preferences', () {
    test('Default intervals match specifications (Again: 1d, Hard: 2d, Good: 4d, Easy: 7d)', () {
      expect(RevisionConfidence.again.defaultIntervalDays, equals(1));
      expect(RevisionConfidence.hard.defaultIntervalDays, equals(2));
      expect(RevisionConfidence.good.defaultIntervalDays, equals(4));
      expect(RevisionConfidence.easy.defaultIntervalDays, equals(7));
    });

    test('Custom RevisionPreferences intervals are respected', () {
      const customPrefs = RevisionPreferences(
        againIntervalDays: 2,
        hardIntervalDays: 3,
        goodIntervalDays: 6,
        easyIntervalDays: 14,
      );

      final baseDate = DateTime(2026, 10, 21, 15, 30);
      final nextAgain = srs.calculateNextReviewDate(baseDate, RevisionConfidence.again, preferences: customPrefs);
      final nextHard = srs.calculateNextReviewDate(baseDate, RevisionConfidence.hard, preferences: customPrefs);
      final nextGood = srs.calculateNextReviewDate(baseDate, RevisionConfidence.good, preferences: customPrefs);
      final nextEasy = srs.calculateNextReviewDate(baseDate, RevisionConfidence.easy, preferences: customPrefs);

      expect(nextAgain, equals(DateTime(2026, 10, 23)));
      expect(nextHard, equals(DateTime(2026, 10, 24)));
      expect(nextGood, equals(DateTime(2026, 10, 27)));
      expect(nextEasy, equals(DateTime(2026, 11, 4)));
    });

    test('Date normalization correctly resolves calendar midnight boundaries', () {
      final dt1 = DateTime(2026, 10, 21, 0, 1);
      final dt2 = DateTime(2026, 10, 21, 23, 59);
      expect(srs.normalizeDate(dt1), equals(DateTime(2026, 10, 21)));
      expect(srs.normalizeDate(dt2), equals(DateTime(2026, 10, 21)));
      expect(srs.normalizeDate(dt1), equals(srs.normalizeDate(dt2)));
    });
  });

  group('SpacedRepetitionService - Due Timing Classification', () {
    final now = DateTime(2026, 10, 21, 12, 0);

    test('Overdue classification for past dates', () {
      final pastDate = DateTime(2026, 10, 20);
      expect(srs.isOverdue(pastDate, now: now), isTrue);
      expect(srs.daysOverdue(pastDate, now: now), equals(1));

      final timing = srs.classifyDueTiming(pastDate, LearningStatus.reviewed, null, now: now);
      expect(timing, equals(RevisionDue.overdue));
    });

    test('Due Today classification for today dates', () {
      final todayDate = DateTime(2026, 10, 21);
      expect(srs.isDueToday(todayDate, now: now), isTrue);
      expect(srs.isOverdue(todayDate, now: now), isFalse);

      final timing = srs.classifyDueTiming(todayDate, LearningStatus.reviewed, null, now: now);
      expect(timing, equals(RevisionDue.today));
    });

    test('Upcoming classification for future dates', () {
      final futureDate = DateTime(2026, 10, 25);
      expect(srs.isUpcoming(futureDate, now: now), isTrue);

      final timing = srs.classifyDueTiming(futureDate, LearningStatus.reviewed, null, now: now);
      expect(timing, equals(RevisionDue.upcoming));
    });

    test('Recently reviewed classification for newly completed reviews', () {
      final timing = srs.classifyDueTiming(
        DateTime(2026, 10, 25),
        LearningStatus.reviewed,
        DateTime(2026, 10, 21), // reviewed today
        now: now,
      );
      expect(timing, equals(RevisionDue.recentlyReviewed));
    });
  });

  group('SpacedRepetitionService - Daily Queue Ordering & Priority Rules', () {
    final now = DateTime(2026, 10, 21, 12, 0);

    test('Strict priority ordering: Overdue -> Due Today -> Low Confidence -> Incomplete Checklist', () {
      final pOverdue = PatternSummary(
        id: 'p1',
        name: 'Overdue Pattern',
        category: 'Arrays',
        quickIdea: 'Idea',
        nextReviewDate: DateTime(2026, 10, 19),
        checklistPercentage: 0.9,
      );

      final pToday = PatternSummary(
        id: 'p2',
        name: 'Due Today Pattern',
        category: 'Graphs',
        quickIdea: 'Idea',
        nextReviewDate: DateTime(2026, 10, 21),
        checklistPercentage: 0.8,
      );

      final pLowConf = PatternSummary(
        id: 'p3',
        name: 'Low Confidence Pattern',
        category: 'Trees',
        quickIdea: 'Idea',
        status: LearningStatus.needsRevision,
        nextReviewDate: DateTime(2026, 10, 24),
        lastConfidence: RevisionConfidence.again,
        checklistPercentage: 0.7,
      );

      final pIncomplete = PatternSummary(
        id: 'p4',
        name: 'Incomplete Checklist Pattern',
        category: 'DP',
        quickIdea: 'Idea',
        checklistPercentage: 0.2,
      );

      final ordered = srs.orderDailyQueue([pIncomplete, pToday, pLowConf, pOverdue], now: now);

      expect(ordered.first.id, equals('p1')); // Overdue first
      expect(ordered[1].id, equals('p2')); // Today second
      expect(ordered[2].id, equals('p3')); // Low conf third
      expect(ordered[3].id, equals('p4')); // Incomplete fourth
    });

    test('Removes duplicate patterns in daily queue', () {
      final p1 = PatternSummary(
        id: 'dup_id',
        name: 'Pattern A',
        category: 'Arrays',
        quickIdea: 'Idea',
        nextReviewDate: DateTime(2026, 10, 21),
      );
      final p2 = PatternSummary(
        id: 'dup_id',
        name: 'Pattern A duplicate',
        category: 'Arrays',
        quickIdea: 'Idea',
        nextReviewDate: DateTime(2026, 10, 21),
      );

      final ordered = srs.orderDailyQueue([p1, p2]);
      expect(ordered.length, equals(1));
      expect(ordered.first.id, equals('dup_id'));
    });
  });

  group('Revision Session State Transitions & Edge Cases', () {
    test('Completed review session increments review count and consecutive reviews without auto-mastering', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'two_pointers';

      await container.read(patternDetailsProvider.notifier).recordRevision(
        patternId: patternId,
        confidence: RevisionConfidence.easy,
        checklistCompletion: 1.0,
      );

      final pattern = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(pattern.lastConfidence, equals(RevisionConfidence.easy));
      expect(pattern.status, equals(LearningStatus.reviewed)); // NOT auto-mastered!
      expect(pattern.consecutiveReviews, equals(1));
      expect(pattern.nextReviewDate, isNotNull);

      // Verify history contains record
      final history = await container.read(storageServiceProvider).loadReviewHistory();
      expect(history.any((r) => r.patternId == patternId && r.confidence == RevisionConfidence.easy), isTrue);
    });

    test('Cancelled session preserves checklist updates but does not advance review count or schedule', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'fixed_sliding_window';
      final initialPattern = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      final initialReviews = initialPattern.consecutiveReviews;
      final initialNextReview = initialPattern.nextReviewDate;

      // User modifies checklist during session
      await container.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'idea');
      await container.read(patternDetailsProvider.notifier).toggleChecklistItem(patternId, 'steps');

      // User aborts session without submitting rating
      final afterAbort = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(afterAbort.checklistCompletedIds.contains('idea'), isTrue);
      expect(afterAbort.checklistCompletedIds.contains('steps'), isTrue);
      expect(afterAbort.consecutiveReviews, equals(initialReviews));
      expect(afterAbort.nextReviewDate, equals(initialNextReview));
    });

    test('Manual date changes update nextReviewDate persistently', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const patternId = 'binary_search';
      final targetDate = DateTime(2026, 12, 1);

      await container.read(patternDetailsProvider.notifier).updateNextReviewDate(patternId, targetDate);

      final pattern = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(pattern.nextReviewDate, equals(targetDate));

      // Reload container to test persistence
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      await container2.read(patternDetailsProvider.notifier).loadPersistedState();

      final reloaded = container2.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
      expect(reloaded.nextReviewDate, equals(targetDate));
    });

    test('Daily revision goal and today completion metrics agree across Dashboard and Revision', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set daily goal to 3
      container.read(settingsProvider.notifier).setDailyGoal(3);

      // Complete 2 revisions
      await container.read(patternDetailsProvider.notifier).recordRevision(
        patternId: 'prefix_sum',
        confidence: RevisionConfidence.good,
      );
      await container.read(patternDetailsProvider.notifier).recordRevision(
        patternId: 'two_pointers',
        confidence: RevisionConfidence.easy,
      );

      final stats = container.read(revisionStatsProvider);
      final dueToday = container.read(dueTodayTasksProvider);
      final overdue = container.read(overdueTasksProvider);

      expect(stats.dailyRevisionGoal, equals(3));
      expect(stats.todayCompletedCount, equals(2));
      expect(stats.dueTodayCount, equals(dueToday.length));
      expect(stats.overdueCount, equals(overdue.length));
    });
  });
}
