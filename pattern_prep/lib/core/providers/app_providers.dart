import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/notification_service.dart';
import '../../features/patterns/models/pattern_model.dart';
import '../../features/patterns/data/patterns_data.dart';
import '../../features/revision/models/revision_task_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Storage Service Provider
// ─────────────────────────────────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  return SharedPrefsStorageService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Spaced Repetition & Notification Service Providers
// ─────────────────────────────────────────────────────────────────────────────

final spacedRepetitionServiceProvider = Provider<SpacedRepetitionService>((ref) {
  return const SpacedRepetitionService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Revision Preferences Provider (Spaced repetition intervals & reminders)
// ─────────────────────────────────────────────────────────────────────────────

class RevisionPreferencesNotifier extends Notifier<RevisionPreferences> {
  @override
  RevisionPreferences build() {
    _load();
    return const RevisionPreferences();
  }

  Future<void> _load() async {
    final storage = ref.read(storageServiceProvider);
    final prefs = await storage.loadRevisionPreferences();
    state = prefs;
  }

  Future<void> updateIntervals({
    int? again,
    int? hard,
    int? good,
    int? easy,
  }) async {
    state = state.copyWith(
      againIntervalDays: again,
      hardIntervalDays: hard,
      goodIntervalDays: good,
      easyIntervalDays: easy,
    );
    await ref.read(storageServiceProvider).saveRevisionPreferences(state);
  }

  Future<void> setReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    state = state.copyWith(
      reminderEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
    );
    await ref.read(storageServiceProvider).saveRevisionPreferences(state);

    final notif = ref.read(notificationServiceProvider);
    if (enabled) {
      final dueCount = ref.read(dueTodayTasksProvider).length;
      await notif.scheduleDailyReminder(
        hour: state.reminderHour,
        minute: state.reminderMinute,
        dueCount: dueCount,
      );
    } else {
      await notif.cancelDailyReminder();
    }
  }
}

final revisionPreferencesProvider =
    NotifierProvider<RevisionPreferencesNotifier, RevisionPreferences>(
  RevisionPreferencesNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Settings Provider
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  const AppSettings({
    this.isDarkMode = true,
    this.defaultLanguage = 'cpp',
    this.dailyRevisionGoal = 5,
  });

  final bool isDarkMode;
  final String defaultLanguage; // 'cpp' or 'python'
  final int dailyRevisionGoal;

  AppSettings copyWith({
    bool? isDarkMode,
    String? defaultLanguage,
    int? dailyRevisionGoal,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      dailyRevisionGoal: dailyRevisionGoal ?? this.dailyRevisionGoal,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // Initial sync
    _loadFromStorage();
    return const AppSettings();
  }

  Future<void> _loadFromStorage() async {
    final storage = ref.read(storageServiceProvider);
    final dark = await storage.getTheme(defaultValue: true);
    final lang = await storage.getLanguage(defaultValue: 'cpp');
    final goal = await storage.getDailyGoal(defaultValue: 5);
    state = AppSettings(
      isDarkMode: dark,
      defaultLanguage: lang,
      dailyRevisionGoal: goal,
    );
  }

  void toggleTheme() {
    final updated = !state.isDarkMode;
    state = state.copyWith(isDarkMode: updated);
    ref.read(storageServiceProvider).saveTheme(updated);
  }

  void setLanguage(String lang) {
    state = state.copyWith(defaultLanguage: lang);
    ref.read(storageServiceProvider).saveLanguage(lang);
  }

  void setDailyGoal(int goal) {
    state = state.copyWith(dailyRevisionGoal: goal);
    ref.read(storageServiceProvider).saveDailyGoal(goal);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Pattern Details Provider (Full Pattern Knowledge Base with user state)
// ─────────────────────────────────────────────────────────────────────────────

class PatternDetailsNotifier extends Notifier<List<PatternDetail>> {
  @override
  List<PatternDetail> build() {
    loadPersistedState();
    return List.from(kPatternDetails);
  }

  Future<void> loadPersistedState() async {
    final storage = ref.read(storageServiceProvider);
    final progressMap = await storage.loadAllProgress();

    if (progressMap.isNotEmpty) {
      state = state.map((detail) {
        final saved = progressMap[detail.id];
        if (saved != null) {
          return detail.copyWith(
            status: saved.status,
            isBookmarked: saved.isBookmarked,
            personalNotes: saved.personalNotes,
            checklistCompletedIds: saved.checklistCompletedIds,
            lastReviewedAt: saved.lastReviewedAt,
            nextReviewDate: saved.nextReviewDate,
            lastConfidence: saved.lastConfidence,
            consecutiveReviews: saved.consecutiveReviews,
          );
        }
        return detail;
      }).toList();
    }
  }

  Future<void> toggleBookmark(String id) async {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(isBookmarked: !p.isBookmarked);
      }
      return p;
    }).toList();
    await ref.read(storageServiceProvider).toggleBookmark(id);
  }

  Future<void> updateStatus(String id, LearningStatus status) async {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(status: status);
      }
      return p;
    }).toList();
    await ref.read(storageServiceProvider).saveStatus(id, status);
  }

  Future<void> updateNextReviewDate(String patternId, DateTime nextReviewDate) async {
    state = state.map((p) {
      if (p.id == patternId) {
        return p.copyWith(nextReviewDate: nextReviewDate);
      }
      return p;
    }).toList();
    await ref.read(storageServiceProvider).updateNextReviewDate(patternId, nextReviewDate);
  }

  Future<void> markReviewed(String id) async {
    await recordRevision(
      patternId: id,
      confidence: RevisionConfidence.good,
    );
  }

  Future<void> toggleChecklistItem(String patternId, String itemId) async {
    Set<String> updatedSet = {};
    state = state.map((p) {
      if (p.id == patternId) {
        final set = Set<String>.from(p.checklistCompletedIds);
        if (set.contains(itemId)) {
          set.remove(itemId);
        } else {
          set.add(itemId);
        }
        updatedSet = set;
        return p.copyWith(checklistCompletedIds: set);
      }
      return p;
    }).toList();
    await ref.read(storageServiceProvider).saveChecklist(patternId, updatedSet);
  }

  Future<void> resetChecklist(String patternId) async {
    state = state.map((p) {
      if (p.id == patternId) {
        return p.copyWith(checklistCompletedIds: <String>{});
      }
      return p;
    }).toList();
    await ref.read(storageServiceProvider).resetChecklist(patternId);
  }

  Future<void> savePersonalNotes(String patternId, String notes) async {
    state = state.map((p) {
      if (p.id == patternId) {
        return p.copyWith(personalNotes: notes);
      }
      return p;
    }).toList();
    await ref.read(storageServiceProvider).savePersonalNotes(patternId, notes);
  }

  Future<void> recordRevision({
    required String patternId,
    required RevisionConfidence confidence,
    DateTime? nextReviewDate,
    double checklistCompletion = 0.0,
    String? notes,
    bool isCompleted = true,
  }) async {
    final srs = ref.read(spacedRepetitionServiceProvider);
    final prefs = ref.read(revisionPreferencesProvider);
    final computedNext = nextReviewDate ??
        srs.calculateNextReviewDate(
          DateTime.now(),
          confidence,
          preferences: prefs,
        );

    state = state.map((p) {
      if (p.id == patternId) {
        final LearningStatus newStatus;
        if (confidence == RevisionConfidence.again) {
          newStatus = LearningStatus.needsRevision;
        } else if (p.status == LearningStatus.notStarted) {
          newStatus = LearningStatus.reviewed;
        } else if (p.status == LearningStatus.needsRevision &&
            (confidence == RevisionConfidence.good || confidence == RevisionConfidence.easy)) {
          newStatus = LearningStatus.reviewed;
        } else {
          newStatus = p.status;
        }

        final newConsecutive = (confidence == RevisionConfidence.good || confidence == RevisionConfidence.easy)
            ? p.consecutiveReviews + 1
            : 0;

        return p.copyWith(
          status: newStatus,
          lastReviewedAt: DateTime.now(),
          nextReviewDate: computedNext,
          lastConfidence: confidence,
          consecutiveReviews: newConsecutive,
          personalNotes: notes ?? p.personalNotes,
        );
      }
      return p;
    }).toList();

    await ref.read(storageServiceProvider).recordRevision(
      patternId: patternId,
      confidence: confidence,
      nextReviewDate: computedNext,
      checklistCompletion: checklistCompletion,
      notes: notes,
      isCompleted: isCompleted,
    );

    ref.invalidate(reviewHistoryProvider);
  }

  Future<void> deleteReviewRecord(String recordId) async {
    await ref.read(storageServiceProvider).deleteReviewRecord(recordId);
    ref.invalidate(reviewHistoryProvider);
  }

  PatternDetail? getById(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> resetAll() async {
    await ref.read(storageServiceProvider).resetAllData();
    state = List.from(kPatternDetails);
    ref.invalidate(reviewHistoryProvider);
  }
}

final patternDetailsProvider =
    NotifierProvider<PatternDetailsNotifier, List<PatternDetail>>(
  PatternDetailsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Patterns Summary List Provider (derived from PatternDetails)
// ─────────────────────────────────────────────────────────────────────────────

class PatternsNotifier extends Notifier<List<PatternSummary>> {
  @override
  List<PatternSummary> build() {
    final details = ref.watch(patternDetailsProvider);
    return details.map((d) => PatternSummary(
      id: d.id,
      name: d.name,
      category: d.category,
      quickIdea: d.quickIdea,
      status: d.status,
      checklistPercentage: d.checklistPercentage,
      completedChecklistCount: d.checklistCompletedIds.length,
      isBookmarked: d.isBookmarked,
      lastReviewedAt: d.lastReviewedAt,
      nextReviewDate: d.nextReviewDate,
      lastConfidence: d.lastConfidence,
      consecutiveReviews: d.consecutiveReviews,
    )).toList();
  }

  void toggleBookmark(String id) {
    ref.read(patternDetailsProvider.notifier).toggleBookmark(id);
  }

  void updateStatus(String id, LearningStatus status) {
    ref.read(patternDetailsProvider.notifier).updateStatus(id, status);
  }
}

final patternsProvider =
    NotifierProvider<PatternsNotifier, List<PatternSummary>>(
  PatternsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Derived Providers: Bookmarks & Review History
// ─────────────────────────────────────────────────────────────────────────────

final bookmarkedPatternsProvider = Provider<List<PatternSummary>>((ref) {
  return ref.watch(patternsProvider).where((p) => p.isBookmarked).toList();
});

final reviewHistoryProvider = FutureProvider<List<PatternReviewRecord>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  final history = await storage.loadReviewHistory();
  return history.reversed.toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Revision Tasks Provider (Derived dynamically using SpacedRepetitionService)
// ─────────────────────────────────────────────────────────────────────────────

class RevisionTasksNotifier extends Notifier<List<RevisionTask>> {
  @override
  List<RevisionTask> build() {
    final patterns = ref.watch(patternsProvider);
    final srs = ref.watch(spacedRepetitionServiceProvider);
    final now = DateTime.now();

    final List<RevisionTask> tasks = [];

    for (final p in patterns) {
      final due = srs.classifyDueTiming(
        p.nextReviewDate,
        p.status,
        p.lastReviewedAt,
        now: now,
      );
      final overdueDays = srs.daysOverdue(p.nextReviewDate, now: now);

      String dueLabel;
      if (due == RevisionDue.overdue) {
        dueLabel = overdueDays > 0
            ? 'Overdue by $overdueDays ${overdueDays == 1 ? 'day' : 'days'}'
            : 'Needs Revision';
      } else if (due == RevisionDue.today) {
        dueLabel = 'Due today';
      } else if (due == RevisionDue.recentlyReviewed) {
        dueLabel = 'Recently reviewed';
      } else {
        if (p.nextReviewDate != null) {
          final days = srs.normalizeDate(p.nextReviewDate!).difference(srs.normalizeDate(now)).inDays;
          dueLabel = 'In $days ${days == 1 ? 'day' : 'days'}';
        } else {
          dueLabel = p.status == LearningStatus.notStarted ? 'Not started' : 'Upcoming';
        }
      }

      tasks.add(RevisionTask(
        id: 'task_${p.id}',
        patternId: p.id,
        title: 'Revise ${p.name}',
        patternName: p.name,
        category: p.category,
        due: due,
        checklistPercentage: p.checklistPercentage,
        status: p.status,
        isCompleted: p.status == LearningStatus.reviewed || p.status == LearningStatus.mastered,
        dueLabel: dueLabel,
        lastReviewedAt: p.lastReviewedAt,
        nextReviewDate: p.nextReviewDate,
        lastConfidence: p.lastConfidence,
        daysOverdue: overdueDays > 0 ? overdueDays : 0,
      ));
    }

    return tasks;
  }

  void toggleComplete(String taskId) {
    final task = state.firstWhere((t) => t.id == taskId);
    ref.read(patternDetailsProvider.notifier).markReviewed(task.patternId);
  }
}

final revisionTasksProvider =
    NotifierProvider<RevisionTasksNotifier, List<RevisionTask>>(
  RevisionTasksNotifier.new,
);

final dueTodayTasksProvider = Provider<List<RevisionTask>>((ref) {
  return ref.watch(revisionTasksProvider).where((t) => t.due == RevisionDue.today).toList();
});

final todayTasksProvider = dueTodayTasksProvider;

final overdueTasksProvider = Provider<List<RevisionTask>>((ref) {
  return ref.watch(revisionTasksProvider).where((t) => t.due == RevisionDue.overdue).toList();
});

final upcomingTasksProvider = Provider<List<RevisionTask>>((ref) {
  return ref.watch(revisionTasksProvider).where((t) => t.due == RevisionDue.upcoming).toList();
});

final recentlyReviewedTasksProvider = Provider<List<RevisionTask>>((ref) {
  return ref.watch(revisionTasksProvider).where((t) => t.due == RevisionDue.recentlyReviewed).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Daily Revision Queue Provider
// ─────────────────────────────────────────────────────────────────────────────

final dailyQueueProvider = Provider<List<PatternSummary>>((ref) {
  final patterns = ref.watch(patternsProvider);
  final srs = ref.watch(spacedRepetitionServiceProvider);
  return srs.orderDailyQueue(patterns);
});

// ─────────────────────────────────────────────────────────────────────────────
// Revision Statistics Provider (Strictly computed from underlying state)
// ─────────────────────────────────────────────────────────────────────────────

class RevisionStats {
  const RevisionStats({
    required this.totalPatterns,
    required this.reviewedCount,
    required this.notStartedCount,
    required this.needsRevisionCount,
    required this.masteredCount,
    required this.learningCount,
    required this.avgChecklistCompletion,
    required this.revisionSessionsCompleted,
    required this.reviewedThisWeekCount,
    required this.categoryProgress,
    required this.weakestPatterns,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.todayCompletedCount,
    required this.dailyRevisionGoal,
  });

  final int totalPatterns;
  final int reviewedCount;
  final int notStartedCount;
  final int needsRevisionCount;
  final int masteredCount;
  final int learningCount;
  final double avgChecklistCompletion;
  final int revisionSessionsCompleted;
  final int reviewedThisWeekCount;
  final Map<String, double> categoryProgress;
  final List<PatternSummary> weakestPatterns;
  final int dueTodayCount;
  final int overdueCount;
  final int todayCompletedCount;
  final int dailyRevisionGoal;
}

final revisionStatsProvider = Provider<RevisionStats>((ref) {
  final patterns = ref.watch(patternsProvider);
  final srs = ref.watch(spacedRepetitionServiceProvider);
  final settings = ref.watch(settingsProvider);
  final dueTodayTasks = ref.watch(dueTodayTasksProvider);
  final overdueTasks = ref.watch(overdueTasksProvider);

  final totalPatterns = patterns.length;

  int reviewed = 0;
  int notStarted = 0;
  int needsRevision = 0;
  int mastered = 0;
  int learning = 0;
  double totalChecklistPercent = 0.0;
  int reviewedThisWeek = 0;
  int todayCompleted = 0;

  final now = DateTime.now();
  final todayNormalized = srs.normalizeDate(now);

  for (final p in patterns) {
    totalChecklistPercent += p.checklistPercentage;
    switch (p.status) {
      case LearningStatus.notStarted:
        notStarted++;
        break;
      case LearningStatus.learning:
        learning++;
        break;
      case LearningStatus.needsRevision:
        needsRevision++;
        break;
      case LearningStatus.reviewed:
        reviewed++;
        break;
      case LearningStatus.mastered:
        mastered++;
        break;
    }

    if (p.lastReviewedAt != null) {
      final daysDiff = now.difference(p.lastReviewedAt!).inDays;
      if (daysDiff <= 7) {
        reviewedThisWeek++;
      }
      if (srs.normalizeDate(p.lastReviewedAt!).isAtSameMomentAs(todayNormalized)) {
        todayCompleted++;
      }
    }
  }

  final avgChecklist = totalPatterns == 0 ? 0.0 : totalChecklistPercent / totalPatterns;

  // Category progress map
  final Map<String, List<PatternSummary>> catMap = {};
  for (final p in patterns) {
    catMap.putIfAbsent(p.category, () => []).add(p);
  }
  final Map<String, double> catProgress = {};
  catMap.forEach((cat, list) {
    final catAvg = list.map((p) => p.checklistPercentage).reduce((a, b) => a + b) / list.length;
    catProgress[cat] = catAvg;
  });

  // Weakest patterns: sort by lowest checklist percentage, prioritizing needsRevision / learning
  final weakest = List<PatternSummary>.from(patterns)
    ..sort((a, b) {
      if (a.status == LearningStatus.needsRevision && b.status != LearningStatus.needsRevision) return -1;
      if (b.status == LearningStatus.needsRevision && a.status != LearningStatus.needsRevision) return 1;
      return a.checklistPercentage.compareTo(b.checklistPercentage);
    });

  return RevisionStats(
    totalPatterns: totalPatterns,
    reviewedCount: reviewed,
    notStartedCount: notStarted,
    needsRevisionCount: needsRevision,
    masteredCount: mastered,
    learningCount: learning,
    avgChecklistCompletion: avgChecklist,
    revisionSessionsCompleted: reviewed + mastered,
    reviewedThisWeekCount: reviewedThisWeek,
    categoryProgress: catProgress,
    weakestPatterns: weakest.take(5).toList(),
    dueTodayCount: dueTodayTasks.length,
    overdueCount: overdueTasks.length,
    todayCompletedCount: todayCompleted,
    dailyRevisionGoal: settings.dailyRevisionGoal,
  );
});
