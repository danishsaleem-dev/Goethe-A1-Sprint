import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';

/// Runs a list of questions one by one with instant feedback.
/// [onComplete] receives the score in percent when the last question is done.
class QuizScreen extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final void Function(int percent)? onComplete;

  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
    this.onComplete,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  int correct = 0;
  bool checked = false;
  bool lastRight = false;
  bool finished = false;
  final List<Question> wrong = [];

  int? selected;
  final TextEditingController ctrl = TextEditingController();
  List<String> chips = [];
  List<bool> used = [];
  List<int> picked = [];

  Question get q => widget.questions[index];
  int get total => widget.questions.length;
  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    ctrl.dispose();
    Speaker.stop();
    super.dispose();
  }

  void _prepare() {
    selected = null;
    ctrl.clear();
    checked = false;
    picked = [];
    if (q.type == QType.order) {
      final words = q.answers.first.split(' ').where((w) => w.isNotEmpty).toList();
      words.addAll(q.extra);
      final original = words.join(' ');
      final rnd = Random(index * 31 + 7);
      for (var i = 0; i < 10; i++) {
        words.shuffle(rnd);
        if (words.join(' ') != original) break;
      }
      chips = words;
      used = List<bool>.filled(words.length, false);
    } else {
      chips = [];
      used = [];
    }
  }

  bool get _canCheck {
    if (q.type == QType.mc) return selected != null;
    if (q.type == QType.fill) return ctrl.text.trim().isNotEmpty;
    return picked.isNotEmpty;
  }

  void _check() {
    if (checked || !_canCheck) return;
    bool ok;
    if (q.type == QType.mc) {
      ok = selected == q.answerIndex;
    } else if (q.type == QType.fill) {
      ok = q.isCorrectText(ctrl.text);
    } else {
      ok = q.isCorrectText(picked.map((i) => chips[i]).join(' '));
    }
    FocusScope.of(context).unfocus();
    setState(() {
      checked = true;
      lastRight = ok;
      if (ok) {
        correct++;
      } else {
        wrong.add(q);
      }
    });
  }

  void _next() {
    if (index + 1 >= total) {
      setState(() => finished = true);
      widget.onComplete?.call(percent);
    } else {
      setState(() {
        index++;
        _prepare();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return _result(context);

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isLast = index + 1 >= total;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (index + (checked ? 1 : 0)) / total,
            minHeight: 4,
          ),
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
                    'Question ${index + 1} of $total',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  if (q.ctx != null) ...[
                    SoftCard(child: Text(q.ctx!, style: tt.bodyLarge?.copyWith(height: 1.4))),
                    const SizedBox(height: 14),
                  ],
                  Text(q.q, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  if (q.hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '(${q.hint})',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _answerArea(context),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (checked) _feedback(context),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: checked ? _next : (_canCheck ? _check : null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(checked ? (isLast ? 'See results' : 'Continue') : 'Check'),
                      ),
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

  Widget _answerArea(BuildContext context) {
    if (q.type == QType.mc) {
      return Column(children: [for (var i = 0; i < q.options.length; i++) _optionTile(context, i)]);
    }
    if (q.type == QType.fill) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            enabled: !checked,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _check(),
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: 'Type your answer',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: ä = ae, ö = oe, ü = ue, ß = ss are accepted.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }
    return _orderArea(context);
  }

  Widget _optionTile(BuildContext context, int i) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color border = cs.outlineVariant;
    Color fill = dark ? cs.surfaceContainerHigh : Colors.white;
    var width = 1.0;
    if (checked) {
      if (i == q.answerIndex) {
        border = AppColors.das;
        fill = AppColors.das.withAlpha(30);
        width = 2;
      } else if (i == selected) {
        border = AppColors.die;
        fill = AppColors.die.withAlpha(30);
        width = 2;
      }
    } else if (selected == i) {
      border = cs.primary;
      fill = cs.primary.withAlpha(24);
      width = 2;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: checked ? null : () => setState(() => selected = i),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: width),
          ),
          child: Text(q.options[i], style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }

  Widget _orderArea(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var k = 0; k < picked.length; k++)
                ActionChip(
                  label: Text(chips[picked[k]], style: const TextStyle(fontSize: 18)),
                  onPressed: checked
                      ? null
                      : () => setState(() {
                            used[picked[k]] = false;
                            picked.removeAt(k);
                          }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < chips.length; i++)
              ActionChip(
                label: Text(chips[i], style: const TextStyle(fontSize: 18)),
                onPressed: (used[i] || checked)
                    ? null
                    : () => setState(() {
                          used[i] = true;
                          picked.add(i);
                        }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _feedback(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = lastRight ? AppColors.das : AppColors.die;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(lastRight ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lastRight ? 'Richtig!' : 'Not quite',
                  style: tt.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              if (q.type == QType.order) SpeakButton(text: q.displayAnswer, size: 22),
            ],
          ),
          if (!lastRight) ...[
            const SizedBox(height: 6),
            Text('Answer: ${q.displayAnswer}',
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          ],
          if (q.explain != null) ...[
            const SizedBox(height: 6),
            Text(q.explain!, style: tt.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pct = percent;
    final headline = pct >= 90
        ? 'Ausgezeichnet!'
        : (pct >= 70 ? 'Gut gemacht!' : 'Keep practising');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
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
            const SizedBox(height: 18),
            Text(headline,
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$correct of $total correct',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            if (wrong.isNotEmpty) ...[
              const SectionLabel('Review your mistakes'),
              for (final w in wrong)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.q, style: tt.bodyMedium),
                        const SizedBox(height: 6),
                        Text(w.displayAnswer,
                            style: tt.titleMedium?.copyWith(
                                color: AppColors.das, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            if (wrong.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        title: 'Retry mistakes',
                        questions: List<Question>.from(wrong),
                      ),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Retry mistakes'),
                  ),
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
