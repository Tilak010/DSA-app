import 'package:equatable/equatable.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}

enum ProblemStatus { unsolved, solved, needsRevision }

extension ProblemStatusX on ProblemStatus {
  String get label {
    switch (this) {
      case ProblemStatus.unsolved:
        return 'Unsolved';
      case ProblemStatus.solved:
        return 'Solved';
      case ProblemStatus.needsRevision:
        return 'Needs Revision';
    }
  }
}

class Problem extends Equatable {
  const Problem({
    required this.id,
    required this.title,
    required this.patternId,
    required this.patternName,
    required this.difficulty,
    this.status = ProblemStatus.unsolved,
    this.url,
    this.notes,
  });

  final String id;
  final String title;
  final String patternId;
  final String patternName;
  final Difficulty difficulty;
  final ProblemStatus status;
  final String? url;
  final String? notes;

  bool get isSolved => status == ProblemStatus.solved;

  Problem copyWith({
    ProblemStatus? status,
    String? notes,
  }) {
    return Problem(
      id: id,
      title: title,
      patternId: patternId,
      patternName: patternName,
      difficulty: difficulty,
      status: status ?? this.status,
      url: url,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        patternId,
        patternName,
        difficulty,
        status,
        url,
        notes,
      ];
}
