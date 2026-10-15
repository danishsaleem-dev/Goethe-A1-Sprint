import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const PageHeader(title: 'Mock exams', subtitle: 'Lesen and Hören under exam conditions'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SoftCard(
            color: cs.primary.withAlpha(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How it works', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'The timer starts when you tap Start. In Hören every audio can be played twice. '
                  'There are no minus points, so answer every question. 60% passes, aim for 90% or more.',
                  style: tt.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ),
        for (final m in s.data.mocks) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionLabel(m.title),
          ),
          for (final sec in m.sections)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: SoftCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MockRunnerScreen(mock: m, section: sec)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: (sec.id == 'lesen' ? AppColors.der : AppColors.gold).withAlpha(32),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        sec.id == 'lesen' ? Icons.article_rounded : Icons.headphones_rounded,
                        color: sec.id == 'lesen' ? AppColors.der : AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sec.title,
                              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            '${sec.itemCount} questions · ${sec.minutes} min',
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (s.mockBest.containsKey('${m.id}_${sec.id}'))
                      Pill('${s.mockBest['${m.id}_${sec.id}']}%',
                          color: scoreColor(s.mockBest['${m.id}_${sec.id}']!))
                    else
                      Icon(Icons.play_circle_outline_rounded, color: cs.primary),
                  ],
                ),
              ),
            ),
        ],
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Schreiben and Sprechen are in the Practice tab. For the real thing, also try the free official Goethe A1 Modelltest on goethe.de.',
          ),
        ),
      ],
    );
  }
}

class _Page {
  final String partTitle;
  final String instr;
  final MockClip clip;
  const _Page(this.partTitle, this.instr, this.clip);
}

class MockRunnerScreen extends StatefulWidget {
  final Mock mock;
  final MockSection section;
  const MockRunnerScreen({super.key, required this.mock, required this.section});

  @override
  State<MockRunnerScreen> createState() => _MockRunnerScreenState();
}

class _MockRunnerScreenState extends State<MockRunnerScreen> {
  late List<_Page> pages;
  final Map<String, int> answers = {};
  final Map<int, int> plays = {};
  final Set<int> scriptShown = {};
  int page = 0;
  late int secondsLeft;
  Timer? timer;
  bool playing = false;
  bool finished = false;
  int correct = 0;
  int totalItems = 0;

  @override
  void initState() {
    super.initState();
    pages = [];
    for (final part in widget.section.parts) {
      for (final clip in part.clips) {
        pages.add(_Page(part.title, part.instr, clip));
      }
    }
    totalItems = widget.section.itemCount;
    secondsLeft = widget.section.minutes * 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || finished) return;
      setState(() => secondsLeft--);
      if (secondsLeft <= 0) _finish();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    Speaker.stop();
    super.dispose();
  }

  String _fmt(int sec) {
    final v = sec < 0 ? 0 : sec;
    final m = (v ~/ 60).toString().padLeft(2, '0');
    final r = (v % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  Future<void> _play(int pi) async {
    final used = plays[pi] ?? 0;
    if (used >= 2 || playing) return;
    setState(() {
      plays[pi] = used + 1;
      playing = true;
    });
    await Speaker.speak(cleanForSpeech(pages[pi].clip.audio ?? ''));
    if (mounted) setState(() => playing = false);
  }

  Future<void> _stop() async {
    await Speaker.stop();
    if (mounted) setState(() => playing = false);
  }

  int get _answered => answers.length;

  Future<void> _tryFinish() async {
    if (_answered < totalItems) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Finish now?'),
          content: Text('You answered $_answered of $totalItems questions.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finish')),
          ],
        ),
      );
      if (ok != true) return;
    }
    _finish();
  }

  void _finish() {
    if (finished) return;
    timer?.cancel();
    Speaker.stop();
    var c = 0;
    for (var pi = 0; pi < pages.length; pi++) {
      final items = pages[pi].clip.items;
      for (var ii = 0; ii < items.length; ii++) {
        if (answers['$pi-$ii'] == items[ii].answer) c++;
      }
    }
    final pct = totalItems == 0 ? 0 : (c * 100 / totalItems).round();
    AppScope.of(context).recordMock('${widget.mock.id}_${widget.section.id}', pct);
    setState(() {
      correct = c;
      finished = true;
      playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return _results(context);

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final p = pages[page];
    final isAudio = p.clip.audio != null;
    final low = secondsLeft <= 60;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mock.title} · ${widget.section.title}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Pill(_fmt(secondsLeft), color: low ? AppColors.die : cs.primary)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (page + 1) / pages.length, minHeight: 4),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${p.partTitle} · ${page + 1} of ${pages.length}',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(p.instr, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  if (p.clip.text != null)
                    SoftCard(
                      child: Text(p.clip.text!, style: tt.bodyLarge?.copyWith(height: 1.5)),
                    ),
                  if (isAudio) _audioCard(context),
                  const SizedBox(height: 8),
                  for (var ii = 0; ii < p.clip.items.length; ii++) _itemBlock(context, ii),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: page == 0
                          ? null
                          : () {
                              _stop();
                              setState(() => page--);
                            },
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: page + 1 >= pages.length
                          ? _tryFinish
                          : () {
                              _stop();
                              setState(() => page++);
                            },
                      child: Text(page + 1 >= pages.length ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _audioCard(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final used = plays[page] ?? 0;
    final left = 2 - used;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: (left > 0 && !playing) ? () => _play(page) : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(playing ? 'Playing...' : 'Play audio'),
              ),
              const SizedBox(width: 8),
              if (playing)
                IconButton(onPressed: _stop, icon: const Icon(Icons.stop_rounded)),
              const Spacer(),
              Text(
                '$left of 2 plays left',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() {
              if (scriptShown.contains(page)) {
                scriptShown.remove(page);
              } else {
                scriptShown.add(page);
              }
            }),
            child: Text(scriptShown.contains(page)
                ? 'Hide script'
                : 'No sound? Show the script (not in the real exam)'),
          ),
          if (scriptShown.contains(page))
            Text(pages[page].clip.audio!, style: tt.bodyMedium?.copyWith(height: 1.45)),
        ],
      ),
    );
  }

  Widget _itemBlock(BuildContext context, int ii) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final item = pages[page].clip.items[ii];
    final key = '$page-$ii';
    final chosen = answers[key];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.q, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (var oi = 0; oi < item.options.length; oi++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => answers[key] = oi),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: chosen == oi
                        ? cs.primary.withAlpha(26)
                        : (dark ? cs.surfaceContainerHigh : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: chosen == oi ? cs.primary : cs.outlineVariant,
                      width: chosen == oi ? 2 : 1,
                    ),
                  ),
                  child: Text(item.options[oi], style: tt.bodyLarge),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _results(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pct = totalItems == 0 ? 0 : (correct * 100 / totalItems).round();
    final verdict = pct >= 90
        ? 'Excellent. This is full-marks level.'
        : (pct >= 60
            ? 'Passed. Review the mistakes below to reach 90% or more.'
            : 'Below the pass mark. Repeat the matching lessons and try again.');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mock.title} · ${widget.section.title}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ProgressRing(
                value: pct / 100,
                size: 150,
                stroke: 12,
                color: scoreColor(pct),
                child: Text('$pct%',
                    style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 16),
            Text('$correct of $totalItems correct',
                textAlign: TextAlign.center,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(verdict,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SectionLabel('Review'),
            for (var pi = 0; pi < pages.length; pi++) ..._reviewPage(context, pi),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _reviewPage(BuildContext context, int pi) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final clip = pages[pi].clip;
    final out = <Widget>[];
    for (var ii = 0; ii < clip.items.length; ii++) {
      final item = clip.items[ii];
      final chosen = answers['$pi-$ii'];
      final ok = chosen == item.answer;
      final color = ok ? AppColors.das : AppColors.die;
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(
            borderColor: color.withAlpha(160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.q,
                          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your answer: ${chosen == null ? 'no answer' : item.options[chosen]}',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (!ok)
                  Text('Correct: ${item.options[item.answer]}',
                      style: tt.bodyMedium?.copyWith(
                          color: AppColors.das, fontWeight: FontWeight.w700)),
                if (ii == 0 && (clip.audio != null || clip.text != null)) ...[
                  const SizedBox(height: 8),
                  Text(
                    clip.audio != null ? 'Script: ${clip.audio}' : 'Text: ${clip.text}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return out;
  }
}
