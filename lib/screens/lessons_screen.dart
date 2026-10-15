import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';
import 'flashcards_screen.dart';
import 'quiz_screen.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = s.planDay;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageHeader(
          title: 'Lessons',
          subtitle: '${s.lessonBest.length} of 14 days done',
        ),
        for (final l in s.data.lessons)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SoftCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l)),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (s.lessonBest.containsKey(l.day) ? AppColors.das : cs.primary)
                          .withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${l.day}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: s.lessonBest.containsKey(l.day) ? AppColors.das : cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title,
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${l.questions.length} questions',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (l.day == today) ...[
                    const Pill('Today', color: AppColors.der),
                    const SizedBox(width: 8),
                  ],
                  if (s.lessonBest.containsKey(l.day))
                    Pill('${s.lessonBest[l.day]}%', color: scoreColor(s.lessonBest[l.day]!))
                  else
                    Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: SoftCard(
            color: cs.primary.withAlpha(20),
            child: Text(
              'Days 15 to 17: take the full mock exams in the Exams tab and repeat the lessons where you scored below 90%.',
              style: tt.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void dispose() {
    Speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = widget.lesson;
    final words = l.group == 0
        ? <VocabCard>[]
        : s.data.vocab.where((v) => v.group == l.group).toList();
    final best = s.lessonBest[l.day];

    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${l.day}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(l.title, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (best != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Pill('Best score $best%', color: scoreColor(best)),
                ),
              ),
            if (words.isNotEmpty) ...[
              const SizedBox(height: 16),
              SoftCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlashcardsScreen(custom: words, title: 'Day ${l.day} words'),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.style_rounded, color: AppColors.der),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Practise this day\'s ${words.length} words',
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
            const SectionLabel('Grammar'),
            for (final g in l.grammar)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.heading,
                          style: tt.titleSmall?.copyWith(
                              color: cs.primary, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(g.text, style: tt.bodyLarge?.copyWith(height: 1.45)),
                    ],
                  ),
                ),
              ),
            if (l.dialogue.isNotEmpty) ...[
              const SectionLabel('Read aloud three times'),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in l.dialogue)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(line, style: tt.bodyLarge?.copyWith(height: 1.4)),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => Speaker.speak(cleanForSpeech(l.dialogue.join(' '))),
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Listen'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Speaker.stop(),
                          child: const Text('Stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    title: 'Day ${l.day} quiz',
                    questions: l.questions,
                    onComplete: (p) => s.recordLesson(l.day, p),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Start quiz (${l.questions.length} questions)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
