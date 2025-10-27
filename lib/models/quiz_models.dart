enum QuestionType { standalone, basedOnPassage }

class Passage {
  String id;
  String title;
  String text;

  Passage({required this.id, this.title = '', this.text = ''});

  factory Passage.fromJson(Map<String, dynamic> j) => Passage(
    id: j['id'] as String? ?? 'p1',
    title: j['title'] as String? ?? '',
    text: j['text'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'text': text};
}

class QuestionItem {
  int id;
  String question;
  Map<String, String> choices;
  String answer;
  String? explanation;
  QuestionType type;
  String? passageId;

  QuestionItem({
    required this.id,
    required this.question,
    required this.choices,
    required this.answer,
    this.explanation,
    this.type = QuestionType.standalone,
    this.passageId,
  });

  factory QuestionItem.fromJson(Map<String, dynamic> json) {
    final rawChoices = (json['choices'] as Map<String, dynamic>?) ?? {};
    final Map<String, String> choices = {};
    for (final entry in rawChoices.entries) {
      choices[entry.key.toString()] = entry.value?.toString() ?? '';
    }

    final typeStr = (json['type'] as String?) ?? '';
    final qtype = typeStr == 'basedOnPassage' ? QuestionType.basedOnPassage : QuestionType.standalone;
    final passageIdRaw = (json['passageId'] as String?)?.trim();
    final passageId = (passageIdRaw != null && passageIdRaw.isNotEmpty) ? passageIdRaw : null;

    return QuestionItem(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      choices: {
        'A': choices['A'] ?? '',
        'B': choices['B'] ?? '',
        'C': choices['C'] ?? '',
        'D': choices['D'] ?? '',
      },
      answer: (json['answer'] as String? ?? 'A').toUpperCase(),
      explanation: json['explanation'] as String?,
      type: qtype,
      passageId: passageId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'choices': choices,
    'answer': answer,
    'explanation': explanation ?? '',
    'type': type == QuestionType.basedOnPassage ? 'basedOnPassage' : 'standalone',
    'passageId': passageId ?? '',
  };
}

class Exercise {
  int id;
  String title;
  String instructions;
  List<Passage> passages;
  List<QuestionItem> questions;

  Exercise({
    required this.id,
    required this.title,
    this.instructions = '',
    this.passages = const [],
    this.questions = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    List<Passage> passages = [];
    if (json['passages'] != null && json['passages'] is List) {
      passages = (json['passages'] as List<dynamic>)
          .map((p) => Passage.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } else if (json['passage'] != null && (json['passage'] is String)) {
      final text = json['passage'] as String;
      passages = [Passage(id: 'p1', title: '', text: text)];
    }

    final questionsList = (json['questions'] as List<dynamic>?)
        ?.map((q) => QuestionItem.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList() ??
        [];


    if (passages.length == 1) {
      for (final q in questionsList) {
        if (q.passageId == null && q.type == QuestionType.standalone) {
        }
      }
    }

    return Exercise(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      passages: passages,
      questions: questionsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'instructions': instructions,
    'passages': passages.map((p) => p.toJson()).toList(),
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}

class QuizPack {
  String title;
  String language;
  String level;
  List<Exercise> exercises;

  QuizPack({required this.title, this.language = 'en', this.level = '', this.exercises = const []});

  factory QuizPack.fromJson(Map<String, dynamic> json) {
    return QuizPack(
      title: json['title'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      level: json['level'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'language': language,
    'level': level,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}
