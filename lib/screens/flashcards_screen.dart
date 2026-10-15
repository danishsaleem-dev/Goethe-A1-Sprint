import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';

/// Spaced-repetition review. Pass [custom] to practise a fixed set of words.
class FlashcardsScreen extends StatefulWidget {
  final List<VocabCard>? custom;
  final String? title;
  const FlashcardsScreen({super.key, this.custom, this.title});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<VocabCard> queue = [];
  int total = 0;
  int done = 0;
  int again = 0;
  bool flipped = false;
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      final s = AppScope.of(context);
      queue = widget.custom != null ? List<VocabCard>.from(widget.custom!) : s.buildQueue();
      total = queue.length;
    }
  }

  @override
  void dispose() {
    Speaker.stop();
    super.dispose();
  }

  void grade(Grade g) {
    final s = AppScope.of(context);
    final c = queue.first;
    s.gradeCard(c, g);
    setState(() {
      queue.removeAt(0);
      if (g == Grade.again) {
        again++;
        queue.insert(min(3, queue.length), c);
      } else {
        done++;
      }
      flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Word review'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 1 : done / total,
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: queue.isEmpty ? _finished(context) : _card(context, s, cs, tt),
      ),
    );
  }

  Widget _finished(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, size: 72, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              total == 0 ? 'Nothing to review' : 'Session complete',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              total == 0
                  ? 'Come back later or raise the daily limit in settings.'
                  : '$total cards reviewed · $again repeated',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AppState s, ColorScheme cs, TextTheme tt) {
    final c = queue.first;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: GestureDetector(
              onTap: () => setState(() => flipped = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: dark ? cs.surfaceContainerHigh : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cs.outlineVariant.withAlpha(110)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: flipped ? _back(c, cs, tt) : _front(c, cs, tt),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: flipped
              ? Row(
                  children: [
                    Expanded(child: _gradeButton(s, c, Grade.again, 'Again', AppColors.die)),
                    const SizedBox(width: 10),
                    Expanded(child: _gradeButton(s, c, Grade.good, 'Good', AppColors.der)),
                    const SizedBox(width: 10),
                    Expanded(child: _gradeButton(s, c, Grade.easy, 'Easy', AppColors.das)),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => setState(() => flipped = true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Show answer'),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _front(VocabCard c, ColorScheme cs, TextTheme tt) {
    return Column(
      key: const ValueKey('front'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Pill(c.groupTitle, color: cs.primary),
        const SizedBox(height: 28),
        ArticleText(c.de, size: 36, weight: FontWeight.w800, align: TextAlign.center),
        const SizedBox(height: 16),
        SpeakButton(text: c.speakText, size: 32),
        const SizedBox(height: 28),
        Text(
          'Think of the meaning, then tap to check',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _back(VocabCard c, ColorScheme cs, TextTheme tt) {
    return Column(
      key: const ValueKey('back'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ArticleText(c.de, size: 22, align: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          c.en,
          textAlign: TextAlign.center,
          style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            c.ur,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, color: cs.primary, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        SpeakButton(text: c.speakText, size: 28),
      ],
    );
  }

  Widget _gradeButton(AppState s, VocabCard c, Grade g, String label, Color color) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: color.withAlpha(36),
        foregroundColor: color,
      ),
      onPressed: () => grade(g),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(s.intervalLabel(c.id, g), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
