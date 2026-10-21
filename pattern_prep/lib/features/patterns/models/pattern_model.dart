import 'package:equatable/equatable.dart';

/// Categories defined in the PatternPrep curriculum (Categories A through K).
abstract final class PatternCategories {
  static const String arraysAndStrings = 'Arrays and Strings';
  static const String searchingAndSorting = 'Searching and Sorting';
  static const String linkedLists = 'Linked Lists';
  static const String stacksAndQueues = 'Stacks and Queues';
  static const String recursionAndBacktracking = 'Recursion and Backtracking';
  static const String treesAndBst = 'Trees and Binary Search Trees';
  static const String heaps = 'Heaps';
  static const String graphs = 'Graphs';
  static const String greedyAndIntervals = 'Greedy and Intervals';
  static const String dynamicProgramming = 'Dynamic Programming';
  static const String otherImportantPatterns = 'Other Important Patterns';

  static const List<String> all = [
    arraysAndStrings,
    searchingAndSorting,
    linkedLists,
    stacksAndQueues,
    recursionAndBacktracking,
    treesAndBst,
    heaps,
    graphs,
    greedyAndIntervals,
    dynamicProgramming,
    otherImportantPatterns,
  ];
}

/// Learning & revision status for a DSA pattern.
enum LearningStatus {
  notStarted,
  learning,
  needsRevision,
  reviewed,
  mastered,
}

extension LearningStatusX on LearningStatus {
  String get label {
    switch (this) {
      case LearningStatus.notStarted:
        return 'Not Started';
      case LearningStatus.learning:
        return 'Learning';
      case LearningStatus.needsRevision:
        return 'Needs Revision';
      case LearningStatus.reviewed:
        return 'Reviewed';
      case LearningStatus.mastered:
        return 'Mastered';
    }
  }

  static LearningStatus fromString(String? val) {
    if (val == null) return LearningStatus.notStarted;
    return LearningStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == val.toLowerCase(),
      orElse: () => LearningStatus.notStarted,
    );
  }
}

/// Confidence rating after a revision session.
enum RevisionConfidence {
  again, // Difficult to recall -> next day (default 1 day)
  hard,  // Remembered with help -> 2 days
  good,  // Recalled independently -> 4 days
  easy;  // Confident recall without reveal -> 7 days

  String get label {
    switch (this) {
      case RevisionConfidence.again:
        return 'Again';
      case RevisionConfidence.hard:
        return 'Hard';
      case RevisionConfidence.good:
        return 'Good';
      case RevisionConfidence.easy:
        return 'Easy';
    }
  }

  String get description {
    switch (this) {
      case RevisionConfidence.again:
        return 'Difficult to recall. Revise tomorrow.';
      case RevisionConfidence.hard:
        return 'Remembered parts with help. Revise in 2 days.';
      case RevisionConfidence.good:
        return 'Recalled independently. Revise in 4 days.';
      case RevisionConfidence.easy:
        return 'Effortless recall. Revise in 7 days.';
    }
  }

  int get defaultIntervalDays {
    switch (this) {
      case RevisionConfidence.again:
        return 1;
      case RevisionConfidence.hard:
        return 2;
      case RevisionConfidence.good:
        return 4;
      case RevisionConfidence.easy:
        return 7;
    }
  }
}

/// User's configurable spaced repetition intervals & reminder preferences.
class RevisionPreferences extends Equatable {
  const RevisionPreferences({
    this.againIntervalDays = 1,
    this.hardIntervalDays = 2,
    this.goodIntervalDays = 4,
    this.easyIntervalDays = 7,
    this.reminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  final int againIntervalDays;
  final int hardIntervalDays;
  final int goodIntervalDays;
  final int easyIntervalDays;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  int getIntervalFor(RevisionConfidence confidence) {
    switch (confidence) {
      case RevisionConfidence.again:
        return againIntervalDays;
      case RevisionConfidence.hard:
        return hardIntervalDays;
      case RevisionConfidence.good:
        return goodIntervalDays;
      case RevisionConfidence.easy:
        return easyIntervalDays;
    }
  }

  RevisionPreferences copyWith({
    int? againIntervalDays,
    int? hardIntervalDays,
    int? goodIntervalDays,
    int? easyIntervalDays,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return RevisionPreferences(
      againIntervalDays: againIntervalDays ?? this.againIntervalDays,
      hardIntervalDays: hardIntervalDays ?? this.hardIntervalDays,
      goodIntervalDays: goodIntervalDays ?? this.goodIntervalDays,
      easyIntervalDays: easyIntervalDays ?? this.easyIntervalDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'againIntervalDays': againIntervalDays,
        'hardIntervalDays': hardIntervalDays,
        'goodIntervalDays': goodIntervalDays,
        'easyIntervalDays': easyIntervalDays,
        'reminderEnabled': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory RevisionPreferences.fromJson(Map<String, dynamic> json) {
    return RevisionPreferences(
      againIntervalDays: (json['againIntervalDays'] as int?) ?? 1,
      hardIntervalDays: (json['hardIntervalDays'] as int?) ?? 2,
      goodIntervalDays: (json['goodIntervalDays'] as int?) ?? 4,
      easyIntervalDays: (json['easyIntervalDays'] as int?) ?? 7,
      reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      reminderHour: (json['reminderHour'] as int?) ?? 9,
      reminderMinute: (json['reminderMinute'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        againIntervalDays,
        hardIntervalDays,
        goodIntervalDays,
        easyIntervalDays,
        reminderEnabled,
        reminderHour,
        reminderMinute,
      ];
}

/// A single interactive checklist item for pattern revision.
class ChecklistItem extends Equatable {
  const ChecklistItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final bool isCompleted;

  ChecklistItem copyWith({bool? isCompleted}) {
    return ChecklistItem(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted];
}

/// The 10 standard checklist items for every pattern.
class PatternRevisionChecklist extends Equatable {
  const PatternRevisionChecklist({
    required this.patternId,
    required this.items,
  });

  final String patternId;
  final List<ChecklistItem> items;

  int get completedCount => items.where((i) => i.isCompleted).length;
  int get totalCount => items.length;
  double get completionPercentage =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;

  ChecklistItem? get nextIncompleteItem {
    try {
      return items.firstWhere((i) => !i.isCompleted);
    } catch (_) {
      return null;
    }
  }

  static const List<String> standardItemIds = [
    'idea',
    'when_to_use',
    'clues',
    'algorithm',
    'time_complexity',
    'space_complexity',
    'cpp_template',
    'python_template',
    'mistakes',
    'explain',
  ];

  static const Map<String, String> standardItemTitles = {
    'idea': 'I understand the basic idea.',
    'when_to_use': 'I know when to use this pattern.',
    'clues': 'I can recognize the problem clues.',
    'algorithm': 'I understand the algorithm steps.',
    'time_complexity': 'I remember the time complexity.',
    'space_complexity': 'I remember the space complexity.',
    'cpp_template': 'I can write the C++ template without looking.',
    'python_template': 'I can write the Python template without looking.',
    'mistakes': 'I understand the common mistakes.',
    'explain': 'I can explain the pattern in my own words.',
  };

  factory PatternRevisionChecklist.create(
    String patternId, {
    Set<String> completedIds = const {},
  }) {
    final items = standardItemIds.map((id) {
      return ChecklistItem(
        id: id,
        title: standardItemTitles[id] ?? id,
        isCompleted: completedIds.contains(id),
      );
    }).toList();
    return PatternRevisionChecklist(patternId: patternId, items: items);
  }

  @override
  List<Object?> get props => [patternId, items];
}

/// A logged record of a revision session.
class PatternReviewRecord extends Equatable {
  PatternReviewRecord({
    String? id,
    required this.patternId,
    required this.confidence,
    required this.reviewedAt,
    this.checklistCompletion = 0.0,
    this.nextReviewDate,
    this.notes,
    this.isCompleted = true,
  }) : id = id ?? '${patternId}_${reviewedAt.millisecondsSinceEpoch}';

  final String id;
  final String patternId;
  final RevisionConfidence confidence;
  final DateTime reviewedAt;
  final double checklistCompletion;
  final DateTime? nextReviewDate;
  final String? notes;
  final bool isCompleted;

  PatternReviewRecord copyWith({
    String? id,
    String? patternId,
    RevisionConfidence? confidence,
    DateTime? reviewedAt,
    double? checklistCompletion,
    DateTime? nextReviewDate,
    String? notes,
    bool? isCompleted,
  }) {
    return PatternReviewRecord(
      id: id ?? this.id,
      patternId: patternId ?? this.patternId,
      confidence: confidence ?? this.confidence,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      checklistCompletion: checklistCompletion ?? this.checklistCompletion,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patternId': patternId,
        'confidence': confidence.name,
        'reviewedAt': reviewedAt.toIso8601String(),
        'checklistCompletion': checklistCompletion,
        'nextReviewDate': nextReviewDate?.toIso8601String(),
        'notes': notes,
        'isCompleted': isCompleted,
      };

  factory PatternReviewRecord.fromJson(Map<String, dynamic> json) {
    final reviewedAt = DateTime.parse(json['reviewedAt'] as String);
    final patternId = json['patternId'] as String;
    return PatternReviewRecord(
      id: json['id'] as String? ?? '${patternId}_${reviewedAt.millisecondsSinceEpoch}',
      patternId: patternId,
      confidence: RevisionConfidence.values.firstWhere(
        (c) => c.name == json['confidence'],
        orElse: () => RevisionConfidence.good,
      ),
      reviewedAt: reviewedAt,
      checklistCompletion: (json['checklistCompletion'] as num?)?.toDouble() ?? 0.0,
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.tryParse(json['nextReviewDate'] as String)
          : null,
      notes: json['notes'] as String?,
      isCompleted: (json['isCompleted'] as bool?) ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patternId,
        confidence,
        reviewedAt,
        checklistCompletion,
        nextReviewDate,
        notes,
        isCompleted,
      ];
}

/// User's persistent state for a pattern.
class UserPatternProgress extends Equatable {
  const UserPatternProgress({
    required this.patternId,
    this.status = LearningStatus.notStarted,
    this.checklistCompletedIds = const {},
    this.isBookmarked = false,
    this.lastReviewedAt,
    this.nextReviewDate,
    this.reviewCount = 0,
    this.consecutiveReviews = 0,
    this.personalNotes = '',
    this.lastConfidence,
  });

  final String patternId;
  final LearningStatus status;
  final Set<String> checklistCompletedIds;
  final bool isBookmarked;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewDate;
  final int reviewCount;
  final int consecutiveReviews;
  final String personalNotes;
  final RevisionConfidence? lastConfidence;

  double get checklistPercentage =>
      checklistCompletedIds.length / PatternRevisionChecklist.standardItemIds.length;

  UserPatternProgress copyWith({
    LearningStatus? status,
    Set<String>? checklistCompletedIds,
    bool? isBookmarked,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    int? reviewCount,
    int? consecutiveReviews,
    String? personalNotes,
    RevisionConfidence? lastConfidence,
  }) {
    return UserPatternProgress(
      patternId: patternId,
      status: status ?? this.status,
      checklistCompletedIds:
          checklistCompletedIds ?? this.checklistCompletedIds,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      reviewCount: reviewCount ?? this.reviewCount,
      consecutiveReviews: consecutiveReviews ?? this.consecutiveReviews,
      personalNotes: personalNotes ?? this.personalNotes,
      lastConfidence: lastConfidence ?? this.lastConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'patternId': patternId,
        'status': status.name,
        'checklist': checklistCompletedIds.toList(),
        'isBookmarked': isBookmarked,
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
        'nextReviewDate': nextReviewDate?.toIso8601String(),
        'reviewCount': reviewCount,
        'consecutiveReviews': consecutiveReviews,
        'personalNotes': personalNotes,
        'lastConfidence': lastConfidence?.name,
      };

  factory UserPatternProgress.fromJson(Map<String, dynamic> json) {
    return UserPatternProgress(
      patternId: json['patternId'] as String,
      status: LearningStatusX.fromString(json['status'] as String?),
      checklistCompletedIds:
          (json['checklist'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ??
              {},
      isBookmarked: (json['isBookmarked'] as bool?) ?? false,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.tryParse(json['lastReviewedAt'] as String)
          : null,
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.tryParse(json['nextReviewDate'] as String)
          : null,
      reviewCount: (json['reviewCount'] as int?) ?? 0,
      consecutiveReviews: (json['consecutiveReviews'] as int?) ?? 0,
      personalNotes: (json['personalNotes'] as String?) ?? '',
      lastConfidence: json['lastConfidence'] != null
          ? RevisionConfidence.values.firstWhere(
              (c) => c.name == json['lastConfidence'],
              orElse: () => RevisionConfidence.good,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        patternId,
        status,
        checklistCompletedIds,
        isBookmarked,
        lastReviewedAt,
        nextReviewDate,
        reviewCount,
        consecutiveReviews,
        personalNotes,
        lastConfidence,
      ];
}

/// A single code template with language implementations and complexities.
class CodeTemplate extends Equatable {
  const CodeTemplate({
    required this.title,
    required this.cppCode,
    required this.pythonCode,
    this.description,
    this.timeComplexity,
    this.spaceComplexity,
  });

  final String title;
  final String cppCode;
  final String pythonCode;
  final String? description;
  final String? timeComplexity;
  final String? spaceComplexity;

  @override
  List<Object?> get props => [
        title,
        cppCode,
        pythonCode,
        description,
        timeComplexity,
        spaceComplexity,
      ];
}

/// Full detail model for a DSA pattern with all 14 required sections.
class PatternDetail extends Equatable {
  const PatternDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.quickIdea,
    required this.whenToUse,
    required this.recognitionClues,
    required this.howItWorks,
    required this.variations,
    required this.algorithmSteps,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.codeTemplates,
    required this.commonMistakes,
    required this.edgeCases,
    required this.relatedPatterns,
    this.status = LearningStatus.notStarted,
    this.isBookmarked = false,
    this.personalNotes = '',
    this.checklistCompletedIds = const {},
    this.lastReviewedAt,
    this.nextReviewDate,
    this.lastConfidence,
    this.consecutiveReviews = 0,
  });

  final String id;
  final String name;
  final String category;
  final String quickIdea;
  final List<String> whenToUse;
  final List<String> recognitionClues;
  final String howItWorks;
  final List<String> variations;
  final List<String> algorithmSteps;
  final String timeComplexity;
  final String spaceComplexity;
  final List<CodeTemplate> codeTemplates;
  final List<String> commonMistakes;
  final List<String> edgeCases;
  final List<String> relatedPatterns;
  final LearningStatus status;
  final bool isBookmarked;
  final String personalNotes;
  final Set<String> checklistCompletedIds;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewDate;
  final RevisionConfidence? lastConfidence;
  final int consecutiveReviews;

  PatternRevisionChecklist get checklist =>
      PatternRevisionChecklist.create(id, completedIds: checklistCompletedIds);

  double get checklistPercentage =>
      checklistCompletedIds.length / PatternRevisionChecklist.standardItemIds.length;

  PatternDetail copyWith({
    LearningStatus? status,
    bool? isBookmarked,
    String? personalNotes,
    Set<String>? checklistCompletedIds,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    RevisionConfidence? lastConfidence,
    int? consecutiveReviews,
  }) {
    return PatternDetail(
      id: id,
      name: name,
      category: category,
      quickIdea: quickIdea,
      whenToUse: whenToUse,
      recognitionClues: recognitionClues,
      howItWorks: howItWorks,
      variations: variations,
      algorithmSteps: algorithmSteps,
      timeComplexity: timeComplexity,
      spaceComplexity: spaceComplexity,
      codeTemplates: codeTemplates,
      commonMistakes: commonMistakes,
      edgeCases: edgeCases,
      relatedPatterns: relatedPatterns,
      status: status ?? this.status,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      personalNotes: personalNotes ?? this.personalNotes,
      checklistCompletedIds:
          checklistCompletedIds ?? this.checklistCompletedIds,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastConfidence: lastConfidence ?? this.lastConfidence,
      consecutiveReviews: consecutiveReviews ?? this.consecutiveReviews,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        quickIdea,
        whenToUse,
        recognitionClues,
        howItWorks,
        variations,
        algorithmSteps,
        timeComplexity,
        spaceComplexity,
        codeTemplates,
        commonMistakes,
        edgeCases,
        relatedPatterns,
        status,
        isBookmarked,
        personalNotes,
        checklistCompletedIds,
        lastReviewedAt,
        nextReviewDate,
        lastConfidence,
        consecutiveReviews,
      ];
}

/// Lightweight summary card for list views, filters, and cards.
class PatternSummary extends Equatable {
  const PatternSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.quickIdea,
    this.status = LearningStatus.notStarted,
    this.checklistPercentage = 0.0,
    this.completedChecklistCount = 0,
    this.isBookmarked = false,
    this.lastReviewedAt,
    this.nextReviewDate,
    this.lastConfidence,
    this.consecutiveReviews = 0,
  });

  final String id;
  final String name;
  final String category;
  final String quickIdea;
  final LearningStatus status;
  final double checklistPercentage;
  final int completedChecklistCount;
  final bool isBookmarked;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewDate;
  final RevisionConfidence? lastConfidence;
  final int consecutiveReviews;

  // Backwards compatibility properties
  double get progressPercent => checklistPercentage;
  String get shortDescription => quickIdea;

  PatternSummary copyWith({
    LearningStatus? status,
    double? checklistPercentage,
    int? completedChecklistCount,
    bool? isBookmarked,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    RevisionConfidence? lastConfidence,
    int? consecutiveReviews,
  }) {
    return PatternSummary(
      id: id,
      name: name,
      category: category,
      quickIdea: quickIdea,
      status: status ?? this.status,
      checklistPercentage: checklistPercentage ?? this.checklistPercentage,
      completedChecklistCount:
          completedChecklistCount ?? this.completedChecklistCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastConfidence: lastConfidence ?? this.lastConfidence,
      consecutiveReviews: consecutiveReviews ?? this.consecutiveReviews,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        quickIdea,
        status,
        checklistPercentage,
        completedChecklistCount,
        isBookmarked,
        lastReviewedAt,
        nextReviewDate,
        lastConfidence,
        consecutiveReviews,
      ];
}
