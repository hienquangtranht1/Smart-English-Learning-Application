import 'dart:convert';
import 'quiz_models.dart';

class QuizExerciseAttempt {
  final List<QuestionItem> questions;
  final Map<String, String> userAnswers;

  QuizExerciseAttempt({
    required this.questions,
    required this.userAnswers,
  });

  factory QuizExerciseAttempt.fromJson(Map<String, dynamic> json) {
    final questionsRaw = json['questions'];
    final questionsList = <QuestionItem>[];
    if (questionsRaw is List) {
      for (final item in questionsRaw) {
        if (item is Map<String, dynamic>) {
          questionsList.add(QuestionItem.fromJson(item));
        } else if (item is Map) {
          questionsList.add(QuestionItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final answersRaw = json['userAnswers'];
    final Map<String, String> answersMap = {};
    if (answersRaw is Map) {
      answersMap.addAll(Map<String, String>.from(
          answersRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))));
    }

    return QuizExerciseAttempt(
      questions: questionsList,
      userAnswers: answersMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'questions': questions.map((q) => q.toJson()).toList(),
    'userAnswers': userAnswers,
  };

  String toRawJson() => json.encode(toJson());

  factory QuizExerciseAttempt.fromRawJson(String raw) =>
      QuizExerciseAttempt.fromJson(json.decode(raw) as Map<String, dynamic>);
}
