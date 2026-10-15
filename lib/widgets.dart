import 'package:flutter/material.dart';

import 'theme.dart';
import 'tts.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (dark ? cs.surfaceContainerHigh : Colors.white);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor ?? cs.outlineVariant.withAlpha(110)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// German noun with the article coloured: der = blue, die = red, das = green.
class ArticleText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final TextAlign align;

  const ArticleText(
    this.text, {
    super.key,
    this.size = 17,
    this.weight = FontWeight.w600,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = TextStyle(fontSize: size, fontWeight: weight, color: cs.onSurface, height: 1.25);
    final m = RegExp(r'^(der|die|das)\s+(.*)$').firstMatch(text);
    if (m == null) {
      return Text(text, style: base, textAlign: align);
    }
    final art = m.group(1)!;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: '$art ',
            style: TextStyle(color: AppColors.forArticle(art), fontWeight: FontWeight.w800),
          ),
          TextSpan(text: m.group(2)),
        ],
      ),
      textAlign: align,
    );
  }
}

class SpeakButton extends StatelessWidget {
  final String text;
  final double size;
  const SpeakButton({super.key, required this.text, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Listen',
      onPressed: () => Speaker.speak(cleanForSpeech(text)),
      icon: Icon(Icons.volume_up_rounded, size: size),
    );
  }
}

class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? track;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 80,
    this.stroke = 8,
    this.color,
    this.track,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0).toDouble(),
              strokeWidth: stroke,
              color: color ?? cs.primary,
              backgroundColor: track ?? cs.surfaceContainerHighest,
              strokeCap: StrokeCap.round,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

Color scoreColor(int percent) {
  if (percent >= 90) return AppColors.das;
  if (percent >= 60) return AppColors.gold;
  return AppColors.die;
}
