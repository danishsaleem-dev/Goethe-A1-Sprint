import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_repo.dart';
import 'models.dart';

enum Grade { again, good, easy }

class CardProgress {
  int box;
  int due;
  int reps;
  int lapses;
  CardProgress({this.box = 0, this.due = 0, this.reps = 0, this.lapses = 0});

  Map<String, dynamic> toJson() => {'b': box, 'd': due, 'r': reps, 'l': lapses};

  factory CardProgress.fromJson(Map<String, dynamic> j) => CardProgress(
        box: (j['b'] as num?)?.toInt() ?? 0,
        due: (j['d'] as num?)?.toInt() ?? 0,
        reps: (j['r'] as num?)?.toInt() ?? 0,
        lapses: (j['l'] as num?)?.toInt() ?? 0,
      );
}

String dateKey(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

DateTime _parseKey(String k) {
  final p = k.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  late AppData data;

  final Map<String, CardProgress> cards = {};
  final Map<int, int> lessonBest = {};
  final Map<String, int> mockBest = {};
  final Set<String> studyDays = {};
  final Map<String, String> drafts = {};
  final Map<String, String> profile = {};

  String startKey = '';
  String? examKey;
  int newPerDay = 25;
  int themeIndex = 0;
  String _newDay = '';
  int _newCount = 0;

  /// Review intervals in days for boxes 0..5.
  static const List<int> intervalDays = [0, 1, 3, 7, 14, 30];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    data = await AppData.load();
    _loadAll();
  }

  Map<String, dynamic> _decode(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final v = jsonDecode(raw);
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return {};
  }

  void _loadAll() {
    cards.clear();
    lessonBest.clear();
    mockBest.clear();
    studyDays.clear();
    drafts.clear();
    profile.clear();

    startKey = _prefs.getString('start') ?? '';
    if (startKey.isEmpty) {
      startKey = dateKey(DateTime.now());
      _prefs.setString('start', startKey);
    }
    examKey = _prefs.getString('exam');
    newPerDay = _prefs.getInt('newPerDay') ?? 25;
    themeIndex = _prefs.getInt('theme') ?? 0;
    _newDay = _prefs.getString('newDay') ?? '';
    _newCount = _prefs.getInt('newCount') ?? 0;

    _decode('cards').forEach((k, v) {
      if (v is Map<String, dynamic>) cards[k] = CardProgress.fromJson(v);
    });
    _decode('lessons').forEach((k, v) {
      final d = int.tryParse(k);
      if (d != null && v is num) lessonBest[d] = v.toInt();
    });
    _decode('mocks').forEach((k, v) {
      if (v is num) mockBest[k] = v.toInt();
    });
    _decode('drafts').forEach((k, v) => drafts[k] = v.toString());
    _decode('profile').forEach((k, v) => profile[k] = v.toString());
    studyDays.addAll(_prefs.getStringList('days') ?? const <String>[]);
  }

  // ---------------------------------------------------------------- settings

  ThemeMode get themeMode =>
      const [ThemeMode.system, ThemeMode.light, ThemeMode.dark][themeIndex];

  void setThemeIndex(int i) {
    themeIndex = i;
    _prefs.setInt('theme', i);
    notifyListeners();
  }

  void setNewPerDay(int n) {
    newPerDay = n;
    _prefs.setInt('newPerDay', n);
    notifyListeners();
  }

  void setExamDate(DateTime? d) {
    examKey = d == null ? null : dateKey(d);
    if (examKey == null) {
      _prefs.remove('exam');
    } else {
      _prefs.setString('exam', examKey!);
    }
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _prefs.clear();
    _loadAll();
    notifyListeners();
  }

  // ------------------------------------------------------------- plan / stats

  int get planDay {
    final n = DateTime.now();
    final today = DateTime.utc(n.year, n.month, n.day);
    return max(1, today.difference(_parseKey(startKey)).inDays + 1);
  }

  int? get daysToExam {
    if (examKey == null) return null;
    final n = DateTime.now();
    final today = DateTime.utc(n.year, n.month, n.day);
    return _parseKey(examKey!).difference(today).inDays;
  }

  int get streak {
    var d = DateTime.now();
    var n = 0;
    if (!studyDays.contains(dateKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    while (studyDays.contains(dateKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  int get masteredCount => cards.values.where((c) => c.box >= 3).length;

  double get avgLesson {
    if (lessonBest.isEmpty) return 0;
    var sum = 0;
    for (final v in lessonBest.values) {
      sum += v;
    }
    return sum / lessonBest.length;
  }

  int? bestMock(String sectionId) {
    int? best;
    mockBest.forEach((k, v) {
      if (k.endsWith('_$sectionId') && (best == null || v > best!)) best = v;
    });
    return best;
  }

  void markStudied() {
    final k = dateKey(DateTime.now());
    if (studyDays.add(k)) {
      _prefs.setStringList('days', studyDays.toList());
    }
  }

  // ------------------------------------------------------------ spaced repetition

  void _rollDay() {
    final today = dateKey(DateTime.now());
    if (_newDay != today) {
      _newDay = today;
      _newCount = 0;
    }
  }

  int get dueCount {
    final now = DateTime.now().millisecondsSinceEpoch;
    return cards.values.where((p) => p.due <= now).length;
  }

  int get newAvailable {
    _rollDay();
    final unseen = data.vocab.length - cards.length;
    return max(0, min(unseen, newPerDay - _newCount));
  }

  /// Due cards first (oldest due first), then today's quota of new cards.
  List<VocabCard> buildQueue() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = data.vocab
        .where((c) => cards.containsKey(c.id) && cards[c.id]!.due <= now)
        .toList();
    due.sort((a, b) => cards[a.id]!.due.compareTo(cards[b.id]!.due));
    final fresh =
        data.vocab.where((c) => !cards.containsKey(c.id)).take(newAvailable).toList();
    return [...due, ...fresh];
  }

  String intervalLabel(String id, Grade g) {
    if (g == Grade.again) return '10 min';
    final box = cards[id]?.box ?? 0;
    final nb = min(5, box + (g == Grade.easy ? 2 : 1));
    final d = intervalDays[nb];
    return d == 1 ? '1 day' : '$d days';
  }

  void gradeCard(VocabCard c, Grade g) {
    _rollDay();
    final now = DateTime.now();
    final existing = cards[c.id];
    if (existing == null) {
      _newCount++;
      _prefs.setString('newDay', _newDay);
      _prefs.setInt('newCount', _newCount);
    }
    final p = existing ?? CardProgress();
    p.reps += 1;
    if (g == Grade.again) {
      p.box = 0;
      p.lapses += 1;
      p.due = now.add(const Duration(minutes: 10)).millisecondsSinceEpoch;
    } else {
      p.box = min(5, p.box + (g == Grade.easy ? 2 : 1));
      p.due = now.add(Duration(days: intervalDays[p.box])).millisecondsSinceEpoch;
    }
    cards[c.id] = p;
    markStudied();
    _prefs.setString('cards', jsonEncode(cards.map((k, v) => MapEntry(k, v.toJson()))));
    notifyListeners();
  }

  // ------------------------------------------------------------ quizzes / mocks

  void recordLesson(int day, int percent) {
    final old = lessonBest[day] ?? 0;
    lessonBest[day] = max(old, percent);
    markStudied();
    _prefs.setString('lessons', jsonEncode(lessonBest.map((k, v) => MapEntry('$k', v))));
    notifyListeners();
  }

  void recordMock(String key, int percent) {
    final old = mockBest[key] ?? 0;
    mockBest[key] = max(old, percent);
    markStudied();
    _prefs.setString('mocks', jsonEncode(mockBest));
    notifyListeners();
  }

  // ------------------------------------------------------------ writing / speaking

  void setDraft(String key, String text) {
    drafts[key] = text;
    _prefs.setString('drafts', jsonEncode(drafts));
  }

  void setProfile(String key, String value) {
    profile[key] = value;
    _prefs.setString('profile', jsonEncode(profile));
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
