import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';

class WritingTab extends StatelessWidget {
  const WritingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final w = s.data.writing;
    final forms = (w['forms'] as List).cast<Map<String, dynamic>>();
    final prompts = (w['prompts'] as List).cast<Map<String, dynamic>>();
    final examples = (w['examples'] as List).cast<Map<String, dynamic>>();
    final frames = (w['frames'] as List).cast<Map<String, dynamic>>();
    final phrases = (w['phrases'] as List).cast<Map<String, dynamic>>();
    final checklist = (w['checklist'] as List).map((e) => e.toString()).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const SectionLabel('Teil 1 · Fill in a form'),
        for (final f in forms)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormPracticeScreen(form: f)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_rounded, color: AppColors.der),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(f['title'] as String,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        const SectionLabel('Teil 2 · Short message (about 30 words)'),
        for (final p in prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MessageScreen(prompt: p)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_rounded, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['title'] as String,
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          (s.drafts['msg_${p['id']}'] ?? '').trim().isEmpty
                              ? '3 content points'
                              : 'Draft saved',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        const SectionLabel('Model answers'),
        for (final e in examples)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e['title'] as String,
                            style: tt.titleSmall?.copyWith(
                                color: cs.primary, fontWeight: FontWeight.w800)),
                      ),
                      SpeakButton(text: e['text'] as String, size: 22),
                    ],
                  ),
                  Text(e['task'] as String,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(e['text'] as String, style: tt.bodyLarge?.copyWith(height: 1.45)),
                ],
              ),
            ),
          ),
        const SectionLabel('Sentence frames'),
        for (final f in frames)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['title'] as String,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final line in (f['lines'] as List))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(line.toString(), style: tt.bodyMedium?.copyWith(height: 1.4)),
                    ),
                ],
              ),
            ),
          ),
        const SectionLabel('Phrase bank'),
        SoftCard(
          child: Column(
            children: [
              for (final p in phrases)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(p['p'] as String,
                            style: tt.labelLarge?.copyWith(
                                color: cs.primary, fontWeight: FontWeight.w800)),
                      ),
                      Expanded(
                        child: Text(p['t'] as String,
                            style: tt.bodyMedium?.copyWith(height: 1.4)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SectionLabel('Check before you finish (30 seconds)'),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in checklist)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_rounded, size: 20, color: AppColors.das),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c, style: tt.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Teil 1: copy facts from a text into a form, with automatic checking.
class FormPracticeScreen extends StatefulWidget {
  final Map<String, dynamic> form;
  const FormPracticeScreen({super.key, required this.form});

  @override
  State<FormPracticeScreen> createState() => _FormPracticeScreenState();
}

class _FormPracticeScreenState extends State<FormPracticeScreen> {
  late List<Map<String, dynamic>> fields;
  late List<TextEditingController> ctrls;
  List<bool> ok = [];
  bool checked = false;

  @override
  void initState() {
    super.initState();
    fields = (widget.form['fields'] as List).cast<Map<String, dynamic>>();
    ctrls = [for (var i = 0; i < fields.length; i++) TextEditingController()];
  }

  @override
  void dispose() {
    for (final c in ctrls) {
      c.dispose();
    }
    Speaker.stop();
    super.dispose();
  }

  String _squash(String s) => normalizeAnswer(s).replaceAll(' ', '');

  void _check() {
    FocusScope.of(context).unfocus();
    final result = <bool>[];
    for (var i = 0; i < fields.length; i++) {
      final answers = (fields[i]['a'] as List).map((e) => e.toString()).toList();
      final typed = _squash(ctrls[i].text);
      result.add(answers.any((a) => _squash(a) == typed));
    }
    setState(() {
      ok = result;
      checked = true;
    });
  }

  void _reset() {
    for (final c in ctrls) {
      c.clear();
    }
    setState(() {
      ok = [];
      checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final score = ok.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.form['title'] as String),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Read the text, then fill in the form',
                            style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                      SpeakButton(text: widget.form['text'] as String, size: 22),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.form['text'] as String,
                      style: tt.bodyLarge?.copyWith(height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < fields.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: ctrls[i],
                  enabled: !checked,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: fields[i]['l'] as String,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: checked
                        ? Icon(
                            ok[i] ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: ok[i] ? AppColors.das : AppColors.die,
                          )
                        : null,
                    helperText: (checked && !ok[i])
                        ? 'Answer: ${(fields[i]['a'] as List).first}'
                        : null,
                    helperStyle: const TextStyle(color: AppColors.die),
                  ),
                ),
              ),
            if (checked)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$score of ${fields.length} fields correct',
                  textAlign: TextAlign.center,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            FilledButton(
              onPressed: checked ? _reset : _check,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(checked ? 'Try again' : 'Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teil 2: write a short message with a draft saved on the phone.
class MessageScreen extends StatefulWidget {
  final Map<String, dynamic> prompt;
  const MessageScreen({super.key, required this.prompt});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late TextEditingController ctrl;
  late List<String> points;
  late List<bool> pointsDone;
  late List<String> checklist;
  late List<bool> checkDone;
  bool showModel = false;
  Timer? timer;
  int secondsLeft = 8 * 60;
  bool running = false;
  bool started = false;

  String get _key => 'msg_${widget.prompt['id']}';

  @override
  void initState() {
    super.initState();
    points = (widget.prompt['points'] as List).map((e) => e.toString()).toList();
    pointsDone = List<bool>.filled(points.length, false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      final s = AppScope.of(context);
      ctrl = TextEditingController(text: s.drafts[_key] ?? '');
      checklist = (s.data.writing['checklist'] as List).map((e) => e.toString()).toList();
      checkDone = List<bool>.filled(checklist.length, false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    ctrl.dispose();
    Speaker.stop();
    super.dispose();
  }

  int get words {
    final t = ctrl.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  void _toggleTimer() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
      return;
    }
    if (secondsLeft <= 0) secondsLeft = 8 * 60;
    setState(() => running = true);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => secondsLeft--);
      if (secondsLeft <= 0) {
        t.cancel();
        setState(() => running = false);
      }
    });
  }

  String _fmt(int sec) {
    final v = sec < 0 ? 0 : sec;
    return '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final n = words;
    final wordColor = (n >= 25 && n <= 40) ? AppColors.das : AppColors.gold;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prompt['title'] as String),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.prompt['task'] as String,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Cover all three points:',
                      style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  for (var i = 0; i < points.length; i++)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(points[i]),
                      value: pointsDone[i],
                      onChanged: (v) => setState(() => pointsDone[i] = v ?? false),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Pill('$n words · aim for 25 to 40', color: wordColor),
                const Spacer(),
                TextButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(running ? Icons.pause_rounded : Icons.timer_outlined),
                  label: Text(_fmt(secondsLeft)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              minLines: 6,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (v) {
                s.setDraft(_key, v);
                setState(() {});
              },
              style: const TextStyle(fontSize: 18, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Liebe ..., / Sehr geehrte ...,',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SectionLabel('Self-check'),
            SoftCard(
              child: Column(
                children: [
                  for (var i = 0; i < checklist.length; i++)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(checklist[i]),
                      value: checkDone[i],
                      onChanged: (v) => setState(() => checkDone[i] = v ?? false),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => showModel = !showModel),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(showModel ? 'Hide model answer' : 'Show model answer'),
              ),
            ),
            if (showModel)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SoftCard(
                  color: AppColors.das.withAlpha(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Model answer',
                                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                          SpeakButton(text: widget.prompt['model'] as String, size: 22),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(widget.prompt['model'] as String,
                          style: tt.bodyLarge?.copyWith(height: 1.45)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
