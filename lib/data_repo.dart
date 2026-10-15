import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

class AppData {
  final List<VocabCard> vocab;
  final List<Lesson> lessons;
  final List<Mock> mocks;
  final Map<String, dynamic> writing;
  final Map<String, dynamic> speaking;

  AppData({
    required this.vocab,
    required this.lessons,
    required this.mocks,
    required this.writing,
    required this.speaking,
  });

  static Future<AppData> load() async {
    final vocabRaw = await rootBundle.loadString('assets/data/vocab.txt');
    final vocab = <VocabCard>[];
    var group = 0;
    var groupTitle = '';
    for (final line in const LineSplitter().convert(vocabRaw)) {
      final l = line.trim();
      if (l.isEmpty) continue;
      if (l.startsWith('#')) {
        final parts = l.substring(1).split('|');
        group = int.tryParse(parts[0].trim()) ?? group;
        groupTitle = parts.length > 1 ? parts[1].trim() : '';
        continue;
      }
      final f = l.split('|');
      if (f.length < 3) continue;
      vocab.add(VocabCard(
        id: f[0].trim(),
        de: f[0].trim(),
        en: f[1].trim(),
        ur: f[2].trim(),
        group: group,
        groupTitle: groupTitle,
      ));
    }

    final lessons = <Lesson>[];
    for (var n = 1; n <= 14; n++) {
      final name = 'assets/data/lessons/day${n.toString().padLeft(2, '0')}.json';
      final raw = await rootBundle.loadString(name);
      lessons.add(Lesson.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }

    final mocksRaw = await rootBundle.loadString('assets/data/mocks.json');
    final mocksJson = jsonDecode(mocksRaw) as Map<String, dynamic>;
    final mocks = (mocksJson['mocks'] as List)
        .map((e) => Mock.fromJson(e as Map<String, dynamic>))
        .toList();

    final writing = jsonDecode(await rootBundle.loadString('assets/data/writing.json'))
        as Map<String, dynamic>;
    final speaking = jsonDecode(await rootBundle.loadString('assets/data/speaking.json'))
        as Map<String, dynamic>;

    return AppData(
      vocab: vocab,
      lessons: lessons,
      mocks: mocks,
      writing: writing,
      speaking: speaking,
    );
  }
}
