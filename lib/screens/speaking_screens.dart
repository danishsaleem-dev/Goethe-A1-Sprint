import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';

class SpeakingTab extends StatefulWidget {
  const SpeakingTab({super.key});

  @override
  State<SpeakingTab> createState() => _SpeakingTabState();
}

class _SpeakingTabState extends State<SpeakingTab> {
  final Map<String, TextEditingController> ctrls = {};
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      final s = AppScope.of(context);
      final fields = (s.data.speaking['teil1']['fields'] as List).cast<Map<String, dynamic>>();
      for (final f in fields) {
        final k = f['k'] as String;
        ctrls[k] = TextEditingController(text: s.profile[k] ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _script(Map<String, dynamic> teil1) {
    var t = teil1['template'] as String;
    ctrls.forEach((k, c) {
      final v = c.text.trim();
      t = t.replaceAll('{$k}', v.isEmpty ? '...' : v);
    });
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sp = s.data.speaking;
    final teil1 = sp['teil1'] as Map<String, dynamic>;
    final fields = (teil1['fields'] as List).cast<Map<String, dynamic>>();
    final stuck = (teil1['stuck'] as List).map((e) => e.toString()).toList();
    final teil2 = (sp['teil2'] as List).cast<Map<String, dynamic>>();
    final teil3 = (sp['teil3'] as List).cast<Map<String, dynamic>>();
    final pron = (sp['pron'] as List).map((e) => e.toString()).toList();
    final script = _script(teil1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const SectionLabel('Teil 1 · Introduce yourself'),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fill in your details. Your script is saved on this phone.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              for (final f in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: ctrls[f['k'] as String],
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (v) {
                      s.setProfile(f['k'] as String, v);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: f['k'] as String,
                      hintText: f['hint'] as String,
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(script, style: tt.bodyLarge?.copyWith(height: 1.5)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => Speaker.speak(script),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Listen'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => Speaker.stop(), child: const Text('Stop')),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Say it aloud five times, then record yourself and compare.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SectionLabel('Teil 2 · Ask and answer'),
        _DeckTile(
          title: 'Question cards',
          subtitle: '${teil2.length} cue words. Make the question, then answer in a full sentence.',
          icon: Icons.question_answer_rounded,
          color: AppColors.der,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardDeckScreen(
                title: 'Teil 2 · Questions',
                cards: teil2,
                tip: 'Repeat part of the question in your answer: Wo wohnst du? → Ich wohne in ...',
              ),
            ),
          ),
        ),
        const SectionLabel('Teil 3 · Requests'),
        _DeckTile(
          title: 'Request cards',
          subtitle: '${teil3.length} picture cues. Ask politely, then react.',
          icon: Icons.record_voice_over_rounded,
          color: AppColors.gold,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardDeckScreen(
                title: 'Teil 3 · Requests',
                cards: teil3,
                tip: 'Useful frames: Können Sie bitte ...? · Kannst du bitte ...? · Ich möchte ...',
              ),
            ),
          ),
        ),
        const SectionLabel('If you get stuck'),
        SoftCard(
          child: Column(
            children: [
              for (final p in stuck)
                Row(
                  children: [
                    Expanded(child: Text(p, style: tt.bodyLarge)),
                    SpeakButton(text: p, size: 22),
                  ],
                ),
            ],
          ),
        ),
        const SectionLabel('Pronunciation for Urdu speakers'),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in pron)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 7, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t, style: tt.bodyMedium?.copyWith(height: 1.4))),
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

class _DeckTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DeckTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      onTap: onTap,
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
                Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class CardDeckScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> cards;
  final String tip;

  const CardDeckScreen({
    super.key,
    required this.title,
    required this.cards,
    required this.tip,
  });

  @override
  State<CardDeckScreen> createState() => _CardDeckScreenState();
}

class _CardDeckScreenState extends State<CardDeckScreen> {
  final PageController controller = PageController();
  int page = 0;
  final Set<int> revealed = {};

  @override
  void dispose() {
    controller.dispose();
    Speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} · ${page + 1}/${widget.cards.length}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(widget.tip,
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: widget.cards.length,
                onPageChanged: (i) {
                  Speaker.stop();
                  setState(() => page = i);
                },
                itemBuilder: (context, i) {
                  final c = widget.cards[i];
                  final shown = revealed.contains(i);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: GestureDetector(
                      onTap: () => setState(() => revealed.add(i)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: dark ? cs.surfaceContainerHigh : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: cs.outlineVariant.withAlpha(110)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Pill(c['cue'] as String, color: cs.primary),
                            const SizedBox(height: 24),
                            Text(
                              c['q'] as String,
                              textAlign: TextAlign.center,
                              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            SpeakButton(text: c['q'] as String, size: 28),
                            const SizedBox(height: 16),
                            if (shown) ...[
                              Divider(color: cs.outlineVariant),
                              const SizedBox(height: 12),
                              Text('Sample answer',
                                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                              const SizedBox(height: 6),
                              Text(
                                c['a'] as String,
                                textAlign: TextAlign.center,
                                style: tt.titleLarge?.copyWith(
                                    color: AppColors.das, fontWeight: FontWeight.w700),
                              ),
                              SpeakButton(text: c['a'] as String, size: 26),
                            ] else
                              Text('Answer aloud first, then tap to check',
                                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: page == 0
                          ? null
                          : () => controller.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: page + 1 >= widget.cards.length
                          ? null
                          : () => controller.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      child: const Text('Next'),
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
}
