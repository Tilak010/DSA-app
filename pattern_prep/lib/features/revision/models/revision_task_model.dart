import 'package:equatable/equatable.dart';
import '../../patterns/models/pattern_model.dart';

enum RevisionDue { today, overdue, upcoming, recentlyReviewed }

class RevisionTask extends Equatable {
  const RevisionTask({
    required this.id,
    required this.patternId,
    required this.title,
    required this.patternName,
    required this.category,
    required this.due,
    this.checklistPercentage = 0.0,
    this.status = LearningStatus.learning,
    this.isCompleted = false,
    this.dueLabel,
    this.lastReviewedAt,
    this.nextReviewDate,
    this.lastConfidence,
    this.daysOverdue = 0,
  });

  final String id;
  final String patternId;
  final String title;
  final String patternName;
  final String category;
  final RevisionDue due;
  final double checklistPercentage;
  final LearningStatus status;
  final bool isCompleted;
  final String? dueLabel;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewDate;
  final RevisionConfidence? lastConfidence;
  final int daysOverdue;

  bool get isOverdue => due == RevisionDue.overdue;

  RevisionTask copyWith({
    bool? isCompleted,
    double? checklistPercentage,
    LearningStatus? status,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    RevisionConfidence? lastConfidence,
    RevisionDue? due,
    String? dueLabel,
    int? daysOverdue,
  }) {
    return RevisionTask(
      id: id,
      patternId: patternId,
      title: title,
      patternName: patternName,
      category: category,
      due: due ?? this.due,
      checklistPercentage: checklistPercentage ?? this.checklistPercentage,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      dueLabel: dueLabel ?? this.dueLabel,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastConfidence: lastConfidence ?? this.lastConfidence,
      daysOverdue: daysOverdue ?? this.daysOverdue,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patternId,
        title,
        patternName,
        category,
        due,
        checklistPercentage,
        status,
        isCompleted,
        dueLabel,
        lastReviewedAt,
        nextReviewDate,
        lastConfidence,
        daysOverdue,
      ];
}
