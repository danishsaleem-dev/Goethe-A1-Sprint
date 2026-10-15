/// Lower-cases, strips punctuation and spells umlauts as ae/oe/ue/ss so that
/// "Äpfel" and "aepfel" count as the same answer.
String normalizeAnswer(String s) {
  var t = s.toLowerCase().trim();
  t = t
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');
  t = t.replaceAll(RegExp(r'[.,!?;:"“”„]'), ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

class VocabCard {
  final String id;
  final String de;
  final String en;
  final String ur;
  final int group;
  final String groupTitle;

  const VocabCard({
    required this.id,
    required this.de,
    required this.en,
    required this.ur,
    required this.group,
    required this.groupTitle,
  });

  String? get article {
    final m = RegExp(r'^(der|die|das)\s').firstMatch(de);
    return m?.group(1);
  }

  /// Text for the speech engine: no brackets, slashes become pauses.
  String get speakText {
    var t = de.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    t = t.replaceAll('/', ', ');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class GrammarNote {
  final String heading;
  final String text;
  const GrammarNote(this.heading, this.text);
}

enum QType { mc, fill, order }

class Question {
  final QType type;
  final String q;
  final String? ctx;
  final String? hint;
  final String? explain;
  final List<String> options;
  final int answerIndex;
  final List<String> answers;
  final List<String> extra;

  const Question({
    required this.type,
    required this.q,
    this.ctx,
    this.hint,
    this.explain,
    this.options = const [],
    this.answerIndex = 0,
    this.answers = const [],
    this.extra = const [],
  });

  factory Question.fromJson(Map<String, dynamic> j) {
    final t = j['t'] as String;
    final a = j['a'];
    return Question(
      type: t == 'mc' ? QType.mc : (t == 'fill' ? QType.fill : QType.order),
      q: j['q'] as String,
      ctx: j['c'] as String?,
      hint: j['h'] as String?,
      explain: j['e'] as String?,
      options: ((j['o'] as List?) ?? const []).map((e) => e.toString()).toList(),
      answerIndex: a is int ? a : 0,
      answers: a is List ? a.map((e) => e.toString()).toList() : const [],
      extra: ((j['x'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }

  bool isCorrectText(String input) {
    final n = normalizeAnswer(input);
    for (final a in answers) {
      if (normalizeAnswer(a) == n) return true;
    }
    return false;
  }

  String get displayAnswer {
    if (type == QType.mc) return options[answerIndex];
    return answers.first;
  }
}

class Lesson {
  final int day;
  final String title;
  final int group;
  final List<GrammarNote> grammar;
  final List<String> dialogue;
  final List<Question> questions;

  const Lesson({
    required this.day,
    required this.title,
    required this.group,
    required this.grammar,
    required this.dialogue,
    required this.questions,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) {
    return Lesson(
      day: j['day'] as int,
      title: j['title'] as String,
      group: (j['group'] as int?) ?? 0,
      grammar: ((j['grammar'] as List?) ?? const [])
          .map((e) => GrammarNote(e['h'] as String, e['t'] as String))
          .toList(),
      dialogue: ((j['dialogue'] as List?) ?? const []).map((e) => e.toString()).toList(),
      questions: ((j['questions'] as List?) ?? const [])
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MockItem {
  final String q;
  final List<String> options;
  final int answer;
  const MockItem({required this.q, required this.options, required this.answer});

  factory MockItem.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('r')) {
      final isTrue = j['r'] == true;
      return MockItem(
        q: j['q'] as String,
        options: const ['Richtig', 'Falsch'],
        answer: isTrue ? 0 : 1,
      );
    }
    return MockItem(
      q: j['q'] as String,
      options: (j['o'] as List).map((e) => e.toString()).toList(),
      answer: j['a'] as int,
    );
  }
}

class MockClip {
  final String? text;
  final String? audio;
  final List<MockItem> items;
  const MockClip({this.text, this.audio, required this.items});

  factory MockClip.fromJson(Map<String, dynamic> j) {
    return MockClip(
      text: j['text'] as String?,
      audio: j['audio'] as String?,
      items: (j['items'] as List)
          .map((e) => MockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MockPart {
  final String title;
  final String instr;
  final List<MockClip> clips;
  const MockPart({required this.title, required this.instr, required this.clips});

  factory MockPart.fromJson(Map<String, dynamic> j) {
    return MockPart(
      title: j['title'] as String,
      instr: (j['instr'] as String?) ?? '',
      clips: (j['clips'] as List)
          .map((e) => MockClip.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MockSection {
  final String id;
  final String title;
  final int minutes;
  final List<MockPart> parts;
  const MockSection({
    required this.id,
    required this.title,
    required this.minutes,
    required this.parts,
  });

  int get itemCount {
    var n = 0;
    for (final p in parts) {
      for (final c in p.clips) {
        n += c.items.length;
      }
    }
    return n;
  }

  factory MockSection.fromJson(Map<String, dynamic> j) {
    return MockSection(
      id: j['id'] as String,
      title: j['title'] as String,
      minutes: j['minutes'] as int,
      parts: (j['parts'] as List)
          .map((e) => MockPart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Mock {
  final String id;
  final String title;
  final List<MockSection> sections;
  const Mock({required this.id, required this.title, required this.sections});

  factory Mock.fromJson(Map<String, dynamic> j) {
    return Mock(
      id: j['id'] as String,
      title: j['title'] as String,
      sections: (j['sections'] as List)
          .map((e) => MockSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
