import '../../features/patterns/models/pattern_model.dart';
import '../../features/revision/models/revision_task_model.dart';

class SpacedRepetitionService {
  const SpacedRepetitionService();

  /// Normalizes a DateTime to calendar day boundary (midnight local time 00:00:00).
  DateTime normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Calculates the next review date from review date and confidence rating,
  /// honoring user-configured intervals.
  DateTime calculateNextReviewDate(
    DateTime reviewDate,
    RevisionConfidence rating, {
    RevisionPreferences preferences = const RevisionPreferences(),
  }) {
    final baseDate = normalizeDate(reviewDate);
    final days = preferences.getIntervalFor(rating);
    return baseDate.add(Duration(days: days));
  }

  /// Checks if a date is strictly before today (overdue).
  bool isOverdue(DateTime? date, {DateTime? now}) {
    if (date == null) return false;
    final today = normalizeDate(now ?? DateTime.now());
    return normalizeDate(date).isBefore(today);
  }

  /// Checks if a date is today.
  bool isDueToday(DateTime? date, {DateTime? now}) {
    if (date == null) return false;
    final today = normalizeDate(now ?? DateTime.now());
    return normalizeDate(date).isAtSameMomentAs(today);
  }

  /// Checks if a date is in the future.
  bool isUpcoming(DateTime? date, {DateTime? now}) {
    if (date == null) return false;
    final today = normalizeDate(now ?? DateTime.now());
    return normalizeDate(date).isAfter(today);
  }

  /// Days difference between date and today (positive if overdue, negative if upcoming).
  int daysOverdue(DateTime? date, {DateTime? now}) {
    if (date == null) return 0;
    final today = normalizeDate(now ?? DateTime.now());
    final target = normalizeDate(date);
    return today.difference(target).inDays;
  }

  /// Classifies a pattern into RevisionDue timing.
  RevisionDue classifyDueTiming(
    DateTime? nextReviewDate,
    LearningStatus status,
    DateTime? lastReviewedAt, {
    DateTime? now,
  }) {
    final today = normalizeDate(now ?? DateTime.now());

    // 1. Explicit next review date takes precedence
    if (nextReviewDate != null) {
      final normalizedNext = normalizeDate(nextReviewDate);
      if (normalizedNext.isBefore(today)) {
        return RevisionDue.overdue;
      }
      if (normalizedNext.isAtSameMomentAs(today)) {
        return RevisionDue.today;
      }
      // If reviewed today or recently and next is future
      if (lastReviewedAt != null &&
          today.difference(normalizeDate(lastReviewedAt)).inDays <= 1) {
        return RevisionDue.recentlyReviewed;
      }
      return RevisionDue.upcoming;
    }

    // 2. Patterns without nextReviewDate (not yet reviewed or legacy)
    if (status == LearningStatus.needsRevision) {
      return RevisionDue.overdue;
    }
    if (status == LearningStatus.learning) {
      return RevisionDue.today;
    }
    if (lastReviewedAt != null) {
      final daysSince = today.difference(normalizeDate(lastReviewedAt)).inDays;
      if (daysSince >= 3) {
        return RevisionDue.today;
      }
      return RevisionDue.recentlyReviewed;
    }

    return RevisionDue.upcoming;
  }

  /// Orders patterns into the Daily Revision Queue based on priority rules:
  /// 1. Overdue patterns (most overdue first)
  /// 2. Patterns due today
  /// 3. Patterns with low confidence (Again/Hard)
  /// 4. Patterns with incomplete revision checklists
  List<PatternSummary> orderDailyQueue(
    List<PatternSummary> patterns, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    // Filter to only include patterns that need attention (or unreviewed)
    final candidatePatterns = List<PatternSummary>.from(patterns);

    // Sorting comparator strictly applying the 4 priorities
    candidatePatterns.sort((a, b) {
      final aDue = classifyDueTiming(a.nextReviewDate, a.status, a.lastReviewedAt, now: current);
      final bDue = classifyDueTiming(b.nextReviewDate, b.status, b.lastReviewedAt, now: current);

      // Priority 1: Overdue
      final aIsOverdue = aDue == RevisionDue.overdue;
      final bIsOverdue = bDue == RevisionDue.overdue;
      if (aIsOverdue && !bIsOverdue) return -1;
      if (!aIsOverdue && bIsOverdue) return 1;
      if (aIsOverdue && bIsOverdue) {
        // Most overdue first (earliest nextReviewDate)
        final aDate = a.nextReviewDate ?? DateTime(1970);
        final bDate = b.nextReviewDate ?? DateTime(1970);
        return aDate.compareTo(bDate);
      }

      // Priority 2: Due Today
      final aIsToday = aDue == RevisionDue.today;
      final bIsToday = bDue == RevisionDue.today;
      if (aIsToday && !bIsToday) return -1;
      if (!aIsToday && bIsToday) return 1;

      // Priority 3: Low confidence (Again / Hard)
      final aIsLowConf = a.lastConfidence == RevisionConfidence.again ||
          a.lastConfidence == RevisionConfidence.hard ||
          a.status == LearningStatus.needsRevision;
      final bIsLowConf = b.lastConfidence == RevisionConfidence.again ||
          b.lastConfidence == RevisionConfidence.hard ||
          b.status == LearningStatus.needsRevision;
      if (aIsLowConf && !bIsLowConf) return -1;
      if (!aIsLowConf && bIsLowConf) return 1;

      // Priority 4: Lowest checklist completion percentage
      return a.checklistPercentage.compareTo(b.checklistPercentage);
    });

    // Remove duplicates by ID (if any)
    final seen = <String>{};
    return candidatePatterns.where((p) => seen.add(p.id)).toList();
  }

  /// Evaluates whether a pattern qualifies for automated mastery recommendation
  /// (deliberate mastery criteria: >= 3 consecutive Good/Easy reviews and >= 80% checklist).
  bool qualifiesForMastery(UserPatternProgress progress) {
    return progress.consecutiveReviews >= 3 &&
        progress.checklistPercentage >= 0.8 &&
        progress.lastConfidence != RevisionConfidence.again;
  }
}
