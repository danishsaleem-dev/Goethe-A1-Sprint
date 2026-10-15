// Run once after `flutter create`: dart run tools/setup.dart
// Adds the text-to-speech permission query and the app name to the Android manifest.
import 'dart:io';

void main() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) {
    stderr.writeln('AndroidManifest.xml not found. Run "flutter create --platforms=android ." first.');
    exit(1);
  }
  var s = f.readAsStringSync();
  if (!s.contains('android.intent.action.TTS_SERVICE')) {
    const intent =
        '<intent>\n            <action android:name="android.intent.action.TTS_SERVICE" />\n        </intent>';
    if (s.contains('<queries>')) {
      s = s.replaceFirst('<queries>', '<queries>\n        $intent');
    } else {
      s = s.replaceFirst('<application', '<queries>\n        $intent\n    </queries>\n    <application');
    }
  }
  s = s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Deutsch A1"');
  f.writeAsStringSync(s);
  stdout.writeln('Android manifest updated.');
}
