import 'package:flutter_tts/flutter_tts.dart';

/// Text for the speech engine: removes speaker labels like "A:" and line breaks.
String cleanForSpeech(String s) {
  var t = s.replaceAll(
    RegExp(r'(^|\s)(A|B|Kellner|Gast|Verkäufer|Kunde|Praxis|Patient):\s*'),
    ' ',
  );
  t = t.replaceAll('\n', '. ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// German text-to-speech. Needs a German voice in the phone's text-to-speech
/// settings. Every call is wrapped so a missing voice never crashes the app.
class Speaker {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    _ready = true;
  }

  /// Completes when the speech has finished (or after a safety timeout).
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _init();
      await _tts.stop();
      await _tts.speak(text).timeout(const Duration(seconds: 90), onTimeout: () => null);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
