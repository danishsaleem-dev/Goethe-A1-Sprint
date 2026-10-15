import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'flashcards_screen.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final TextEditingController search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final due = s.dueCount;
    final fresh = s.newAvailable;
    final total = due + fresh;

    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? <VocabCard>[]
        : s.data.vocab
            .where((v) =>
                v.de.toLowerCase().contains(q) ||
                v.en.toLowerCase().contains(q) ||
                v.ur.contains(q))
            .toList();

    final groups = <String, List<VocabCard>>{};
    for (final v in s.data.vocab) {
      groups.putIfAbsent('${v.group}|${v.groupTitle}', () => <VocabCard>[]).add(v);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageHeader(
          title: 'Words',
          subtitle: '${s.data.vocab.length} words with Urdu hints',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SoftCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0 ? 'All caught up' : '$total cards ready',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$due to review · $fresh new today (limit ${s.newPerDay})',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: total == 0
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                            ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start review'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: TextField(
            controller: search,
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'Search German, English or Urdu',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (q.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SectionLabel('Results'),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No matches', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ),
          for (final v in filtered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WordRow(card: v, progress: s.cards[v.id]),
            ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SectionLabel('By theme'),
          ),
          for (final entry in groups.entries)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _GroupTile(
                title: entry.key.split('|').last,
                words: entry.value,
                state: s,
              ),
            ),
        ],
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final String title;
  final List<VocabCard> words;
  final AppState state;

  const _GroupTile({required this.title, required this.words, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final seen = words.where((w) => state.cards.containsKey(w.id)).length;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(110)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '$seen of ${words.length} seen',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
          children: [
            for (final w in words) _WordRow(card: w, progress: state.cards[w.id], plain: true),
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final VocabCard card;
  final CardProgress? progress;
  final bool plain;

  const _WordRow({required this.card, required this.progress, this.plain = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    Color dot = cs.outlineVariant;
    if (progress != null) {
      dot = progress!.box >= 3 ? AppColors.das : AppColors.gold;
    }
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArticleText(card.de, size: 16),
                const SizedBox(height: 2),
                Text(card.en, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                card.ur,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 16, color: cs.primary),
              ),
            ),
          ),
          SpeakButton(text: card.speakText, size: 22),
        ],
      ),
    );
    if (plain) return row;
    return SoftCard(padding: const EdgeInsets.symmetric(horizontal: 14), child: row);
  }
}
