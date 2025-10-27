import 'package:flutter/material.dart';
import '../models/quiz_result.dart';
import '../models/quiz_exercise_attempt.dart';
import '../models/quiz_models.dart';

class HistoryDetailPage extends StatelessWidget {
  final QuizResult result;
  final bool isImmediateResult;

  const HistoryDetailPage({
    super.key,
    required this.result,
    this.isImmediateResult = false,
  });

  String _getQuestionText(QuestionItem q) => q.question;
  Map<String, String> _getChoices(QuestionItem q) => q.choices;
  String _getAnswerKey(QuestionItem q) => q.answer;
  String? _getExplanation(QuestionItem q) => q.explanation;

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green.shade700;
    if (score >= 0.6) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Widget _buildChoiceDisplay(String key, String value, bool isUserAnswer, bool isCorrectAnswer, bool isCorrect) {
    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black87;
    IconData? icon;

    if (isCorrectAnswer) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle_outline;
    }

    if (isUserAnswer) {
      if (isCorrect) {
        backgroundColor = Colors.green.shade200;
        icon = Icons.check_circle;
      } else {
        backgroundColor = Colors.red.shade200;
        textColor = Colors.red.shade900;
        icon = Icons.cancel;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      margin: const EdgeInsets.only(bottom: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isUserAnswer || isCorrectAnswer ? textColor.withOpacity(0.5) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$key. $value',
              style: TextStyle(
                fontWeight: isUserAnswer || isCorrectAnswer ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attempt = result.attemptDetails;
    if (attempt == null) {
      return Scaffold(
        appBar: AppBar(title: Text(result.quizTitle)),
        body: const Center(child: Text('Không có dữ liệu chi tiết cho lần làm bài này.')),
      );
    }

    final questions = attempt.questions;
    final userAnswers = attempt.userAnswers;
    final correctCount = result.correctAnswers;
    final total = result.totalQuestions;
    final percent = total > 0 ? (correctCount / total * 100).round() : 0;
    final scoreColor = _getScoreColor(result.score);

    final closeButtonText = isImmediateResult ? 'Hoàn tất và trở về trang chủ' : 'Quay lại lịch sử';

    void handleClose() {
      if (isImmediateResult) {
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      } else {
        Navigator.of(context).pop();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isImmediateResult ? 'Kết Quả Bài Làm' : 'Chi Tiết Bài Làm'),
        automaticallyImplyLeading: !isImmediateResult,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            width: double.infinity,
            color: scoreColor.withOpacity(0.1),
            child: Column(
                children: [
                  Text(
                    result.quizTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                            '$percent%',
                            style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: scoreColor
                            )
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '($correctCount/$total đúng)',
                            style: const TextStyle(fontSize: 18, color: Colors.black54)
                        ),
                      ]
                  ),
                ]
            ),
          ),
          const Divider(thickness: 2, height: 2),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final qIdKey = q.id.toString();
                final userKey = userAnswers[qIdKey];
                final correctKey = _getAnswerKey(q);
                final choices = _getChoices(q);
                final isCorrect = userKey != null && userKey.toUpperCase() == correctKey.toUpperCase();
                final explanation = _getExplanation(q);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Câu ${index + 1}: ${_getQuestionText(q)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...choices.entries.map((entry) {
                        final key = entry.key;
                        final value = entry.value;
                        final isCorrectAnswer = key.toUpperCase() == correctKey.toUpperCase();
                        final isUserAnswer = userKey != null && key.toUpperCase() == userKey.toUpperCase();

                        return _buildChoiceDisplay(key, value, isUserAnswer, isCorrectAnswer, isCorrect);
                      }).toList(),

                      const SizedBox(height: 10),

                      if (explanation != null && explanation.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💡 Giải thích:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                              ),
                              const SizedBox(height: 4),
                              Text(explanation, style: TextStyle(color: Colors.blue.shade800, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                    ]),
                  ),
                );
              },
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: handleClose,
                  child: Text(closeButtonText, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}