import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const SectionLabel('Exam date'),
            SoftCard(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 14)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (picked != null) s.setExamDate(picked);
              },
              child: Row(
                children: [
                  const Icon(Icons.event_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.examKey ?? 'Tap to set your exam date',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (s.examKey != null)
                    TextButton(
                      onPressed: () => s.setExamDate(null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            const SectionLabel('New words per day'),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.newPerDay} new words each day',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Slider(
                    value: s.newPerDay.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${s.newPerDay}',
                    onChanged: (v) => s.setNewPerDay(v.round()),
                  ),
                  Text(
                    '25 matches the 14-day plan. Raise it if you want to go faster.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SectionLabel('Appearance'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 0, label: Text('System')),
                  ButtonSegment<int>(value: 1, label: Text('Light')),
                  ButtonSegment<int>(value: 2, label: Text('Dark')),
                ],
                selected: {s.themeIndex},
                onSelectionChanged: (set) => s.setThemeIndex(set.first),
              ),
            ),
            const SectionLabel('Audio'),
            SoftCard(
              child: Text(
                'Listening exercises use your phone\'s text-to-speech. If you hear nothing or the wrong accent, open Android Settings, search for "Text-to-speech output" and install the German voice.',
                style: tt.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
            const SectionLabel('Data'),
            OutlinedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset all progress?'),
                    content: const Text(
                        'Flashcard progress, quiz scores, mock scores, drafts and your streak will be deleted.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reset')),
                    ],
                  ),
                );
                if (ok == true) await s.resetAll();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Reset progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
