import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lessons_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int) onGo;
  const HomeScreen({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final day = s.planDay;
    final sprintDone = day > 14;
    final shownDay = day > 14 ? 14 : day;
    final lesson = s.data.lessons[shownDay - 1];
    final due = s.dueCount;
    final fresh = s.newAvailable;
    final exam = s.daysToExam;

    String examText;
    if (exam == null) {
      examText = 'Set your exam date in settings';
    } else if (exam > 0) {
      examText = '$exam days to your exam';
    } else if (exam == 0) {
      examText = 'Your exam is today. Viel Erfolg!';
    } else {
      examText = 'Exam date has passed';
    }

    final lesenBest = s.bestMock('lesen');
    final hoerenBest = s.bestMock('hoeren');

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageHeader(
          title: 'Hallo!',
          subtitle: 'Goethe A1 Sprint',
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.tertiary],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sprintDone ? 'Exam week' : 'Day $shownDay of 14',
                        style: tt.labelLarge?.copyWith(color: cs.onPrimary.withAlpha(220)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sprintDone ? 'Mocks and weak spots' : lesson.title,
                        style: tt.titleLarge?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        examText,
                        style: tt.bodyMedium?.copyWith(color: cs.onPrimary.withAlpha(230)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ProgressRing(
                  value: shownDay / 14,
                  size: 78,
                  stroke: 8,
                  color: cs.onPrimary,
                  track: cs.onPrimary.withAlpha(60),
                  child: Text(
                    '$shownDay',
                    style: tt.titleLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionLabel('Today'),
        ),
        _TaskTile(
          icon: Icons.style_rounded,
          color: AppColors.der,
          title: 'Word review',
          subtitle: (due + fresh) == 0
              ? 'All caught up'
              : '$due due · $fresh new words',
          done: (due + fresh) == 0,
          onTap: () => onGo(1),
        ),
        _TaskTile(
          icon: Icons.menu_book_rounded,
          color: AppColors.das,
          title: sprintDone ? 'Repeat any lesson' : 'Lesson $shownDay: ${lesson.title}',
          subtitle: s.lessonBest.containsKey(shownDay)
              ? 'Best score ${s.lessonBest[shownDay]}%'
              : 'Grammar, dialogue and quiz',
          done: s.lessonBest.containsKey(shownDay),
          onTap: () {
            if (sprintDone) {
              onGo(2);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
              );
            }
          },
        ),
        _TaskTile(
          icon: Icons.mic_rounded,
          color: AppColors.gold,
          title: 'Speaking drill',
          subtitle: 'Teil 1 script and question cards, 15 minutes',
          done: false,
          onTap: () => onGo(4),
        ),
        _TaskTile(
          icon: Icons.edit_rounded,
          color: AppColors.die,
          title: 'Write one message',
          subtitle: 'About 30 words with a greeting and closing',
          done: false,
          onTap: () => onGo(4),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${s.streak}',
                  label: 'day streak',
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.translate_rounded,
                  value: '${s.cards.length}/${s.data.vocab.length}',
                  label: 'words seen',
                  color: AppColors.der,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.verified_rounded,
                  value: '${s.masteredCount}',
                  label: 'mastered',
                  color: AppColors.das,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionLabel('Exam readiness'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SoftCard(
            onTap: () => onGo(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReadinessRow(label: 'Lesen', percent: lesenBest),
                const SizedBox(height: 12),
                _ReadinessRow(label: 'Hören', percent: hoerenBest),
                const SizedBox(height: 12),
                Text(
                  'Pass mark is 60%. Aim for 90% or more in both mocks before the exam.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  const _TaskTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(32),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: done ? AppColors.das : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final int? percent;
  const _ReadinessRow({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final p = percent;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (p ?? 0) / 100,
              minHeight: 10,
              color: p == null ? null : scoreColor(p),
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            p == null ? 'not yet' : '$p%',
            textAlign: TextAlign.right,
            style: tt.labelLarge,
          ),
        ),
      ],
    );
  }
}
