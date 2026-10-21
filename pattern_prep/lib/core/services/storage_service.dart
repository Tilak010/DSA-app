import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/patterns/models/pattern_model.dart';

abstract class StorageService {
  Future<void> init();
  Future<Map<String, UserPatternProgress>> loadAllProgress();
  Future<void> saveProgress(UserPatternProgress progress);
  Future<void> saveChecklist(String patternId, Set<String> completedIds);
  Future<void> resetChecklist(String patternId);
  Future<void> saveStatus(String patternId, LearningStatus status);
  Future<void> toggleBookmark(String patternId);
  Future<void> savePersonalNotes(String patternId, String notes);
  Future<void> recordRevision({
    required String patternId,
    required RevisionConfidence confidence,
    DateTime? nextReviewDate,
    double checklistCompletion = 0.0,
    String? notes,
    bool isCompleted = true,
  });
  Future<void> updateNextReviewDate(String patternId, DateTime nextReviewDate);
  Future<void> deleteReviewRecord(String recordId);
  Future<List<PatternReviewRecord>> loadReviewHistory();
  Future<int> getRevisionSessionsCount();
  Future<void> incrementRevisionSessions();
  Future<bool> getTheme({bool defaultValue = true});
  Future<void> saveTheme(bool isDark);
  Future<String> getLanguage({String defaultValue = 'cpp'});
  Future<void> saveLanguage(String lang);
  Future<int> getDailyGoal({int defaultValue = 5});
  Future<void> saveDailyGoal(int goal);
  Future<RevisionPreferences> loadRevisionPreferences();
  Future<void> saveRevisionPreferences(RevisionPreferences preferences);
  Future<void> resetAllData();
}

class SharedPrefsStorageService implements StorageService {
  SharedPrefsStorageService([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _keyPrefixProgress = 'pattern_prep_progress_';
  static const _keyReviewHistory = 'pattern_prep_review_history';
  static const _keySessionsCount = 'pattern_prep_sessions_count';
  static const _keyThemeDark = 'pattern_prep_theme_dark';
  static const _keyDefaultLang = 'pattern_prep_default_lang';
  static const _keyDailyGoal = 'pattern_prep_daily_goal';
  static const _keyPreferences = 'pattern_prep_revision_preferences';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<Map<String, UserPatternProgress>> loadAllProgress() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefixProgress));
    final Map<String, UserPatternProgress> map = {};

    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          final progress = UserPatternProgress.fromJson(jsonMap);
          map[progress.patternId] = progress;
        } catch (_) {}
      }
    }
    return map;
  }

  @override
  Future<void> saveProgress(UserPatternProgress progress) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      '$_keyPrefixProgress${progress.patternId}',
      jsonEncode(progress.toJson()),
    );
  }

  @override
  Future<void> saveChecklist(String patternId, Set<String> completedIds) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefixProgress$patternId';
    UserPatternProgress current;
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      try {
        current = UserPatternProgress.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        current = UserPatternProgress(patternId: patternId);
      }
    } else {
      current = UserPatternProgress(patternId: patternId);
    }

    final updated = current.copyWith(checklistCompletedIds: completedIds);
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }

  @override
  Future<void> resetChecklist(String patternId) async {
    await saveChecklist(patternId, {});
  }

  @override
  Future<void> saveStatus(String patternId, LearningStatus status) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefixProgress$patternId';
    UserPatternProgress current;
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      try {
        current = UserPatternProgress.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        current = UserPatternProgress(patternId: patternId);
      }
    } else {
      current = UserPatternProgress(patternId: patternId);
    }

    final updated = current.copyWith(status: status);
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }

  @override
  Future<void> toggleBookmark(String patternId) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefixProgress$patternId';
    UserPatternProgress current;
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      try {
        current = UserPatternProgress.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        current = UserPatternProgress(patternId: patternId);
      }
    } else {
      current = UserPatternProgress(patternId: patternId);
    }

    final updated = current.copyWith(isBookmarked: !current.isBookmarked);
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }

  @override
  Future<void> savePersonalNotes(String patternId, String notes) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefixProgress$patternId';
    UserPatternProgress current;
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      try {
        current = UserPatternProgress.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        current = UserPatternProgress(patternId: patternId);
      }
    } else {
      current = UserPatternProgress(patternId: patternId);
    }

    final updated = current.copyWith(personalNotes: notes);
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }

  @override
  Future<void> recordRevision({
    required String patternId,
    required RevisionConfidence confidence,
    DateTime? nextReviewDate,
    double checklistCompletion = 0.0,
    String? notes,
    bool isCompleted = true,
  }) async {
    final prefs = await _getPrefs();
    final record = PatternReviewRecord(
      patternId: patternId,
      confidence: confidence,
      reviewedAt: DateTime.now(),
      checklistCompletion: checklistCompletion,
      nextReviewDate: nextReviewDate,
      notes: notes,
      isCompleted: isCompleted,
    );

    // 1. Add to history
    final history = await loadReviewHistory();
    history.add(record);
    final historyJson = jsonEncode(history.map((r) => r.toJson()).toList());
    await prefs.setString(_keyReviewHistory, historyJson);

    // 2. Update pattern progress
    final key = '$_keyPrefixProgress$patternId';
    UserPatternProgress current;
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      try {
        current = UserPatternProgress.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        current = UserPatternProgress(patternId: patternId);
      }
    } else {
      current = UserPatternProgress(patternId: patternId);
    }

    // Status transition: never auto-master.
    // If difficult/again, mark needsRevision.
    // If previously notStarted, mark reviewed.
    final LearningStatus newStatus;
    if (confidence == RevisionConfidence.again) {
      newStatus = LearningStatus.needsRevision;
    } else if (current.status == LearningStatus.notStarted) {
      newStatus = LearningStatus.reviewed;
    } else if (current.status == LearningStatus.needsRevision &&
        (confidence == RevisionConfidence.good || confidence == RevisionConfidence.easy)) {
      newStatus = LearningStatus.reviewed;
    } else {
      newStatus = current.status;
    }

    final newConsecutive = (confidence == RevisionConfidence.good || confidence == RevisionConfidence.easy)
        ? current.consecutiveReviews + 1
        : 0;

    final updated = current.copyWith(
      lastReviewedAt: record.reviewedAt,
      nextReviewDate: nextReviewDate,
      reviewCount: current.reviewCount + 1,
      consecutiveReviews: newConsecutive,
      lastConfidence: confidence,
      status: newStatus,
    );
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }

  @override
  Future<void> updateNextReviewDate(String patternId, DateTime nextReviewDate) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefixProgress$patternId';
    UserPatternProgress current;
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      try {
        current = UserPatternProgress.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        current = UserPatternProgress(patternId: patternId);
      }
    } else {
      current = UserPatternProgress(patternId: patternId);
    }

    final updated = current.copyWith(nextReviewDate: nextReviewDate);
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }

  @override
  Future<void> deleteReviewRecord(String recordId) async {
    final prefs = await _getPrefs();
    final history = await loadReviewHistory();
    history.removeWhere((r) => r.id == recordId);
    final historyJson = jsonEncode(history.map((r) => r.toJson()).toList());
    await prefs.setString(_keyReviewHistory, historyJson);
  }

  @override
  Future<RevisionPreferences> loadRevisionPreferences() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyPreferences);
    if (jsonStr == null) return const RevisionPreferences();
    try {
      return RevisionPreferences.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return const RevisionPreferences();
    }
  }

  @override
  Future<void> saveRevisionPreferences(RevisionPreferences preferences) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyPreferences, jsonEncode(preferences.toJson()));
  }

  @override
  Future<List<PatternReviewRecord>> loadReviewHistory() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyReviewHistory);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => PatternReviewRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<int> getRevisionSessionsCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keySessionsCount) ?? 0;
  }

  @override
  Future<void> incrementRevisionSessions() async {
    final prefs = await _getPrefs();
    final current = prefs.getInt(_keySessionsCount) ?? 0;
    await prefs.setInt(_keySessionsCount, current + 1);
  }

  @override
  Future<bool> getTheme({bool defaultValue = true}) async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyThemeDark) ?? defaultValue;
  }

  @override
  Future<void> saveTheme(bool isDark) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyThemeDark, isDark);
  }

  @override
  Future<String> getLanguage({String defaultValue = 'cpp'}) async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyDefaultLang) ?? defaultValue;
  }

  @override
  Future<void> saveLanguage(String lang) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyDefaultLang, lang);
  }

  @override
  Future<int> getDailyGoal({int defaultValue = 5}) async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyDailyGoal) ?? defaultValue;
  }

  @override
  Future<void> saveDailyGoal(int goal) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyDailyGoal, goal);
  }

  @override
  Future<void> resetAllData() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys().toList();
    for (final k in keys) {
      if (k.startsWith('pattern_prep_')) {
        await prefs.remove(k);
      }
    }
  }
}
