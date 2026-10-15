# Deutsch A1 – Goethe A1 Sprint app

Offline Flutter app (Android) for a 14-day Goethe-Zertifikat A1 sprint.

## What is inside

| Tab | What it does |
| --- | --- |
| Home | Day of the plan, exam countdown, today's tasks, streak, exam readiness |
| Words | 329 words with Urdu hints, spaced-repetition flashcards (Again / Good / Easy), search, listen button |
| Lessons | 14 days: grammar notes, read-aloud dialogue, quiz with 199 auto-checked questions (fill in, multiple choice, build the sentence) |
| Exams | Timed Lesen and Hören mocks (2 mocks), audio played twice, review with the correct answers |
| Practice | Writing: forms with checking, 6 message prompts with word count and timer, model answers, phrase bank. Speaking: Teil 1 script builder, Teil 2 and 3 cards |

Progress is stored on the phone. German audio uses the phone's text-to-speech.

## First run (Windows PowerShell, Flutter installed)

```powershell
cd "C:\Users\Danish\Documents\GitHub\Goethe A1 Sprint"
flutter create --platforms=android --project-name german_a1 --org com.danish .
dart run tools/setup.dart
flutter pub get
flutter run
```

1. `flutter create` adds the missing Android project files and keeps the code in `lib/`.
   If it ever replaces `lib/main.dart`, copy `tools/main.dart.backup` back over it.
2. `dart run tools/setup.dart` adds the text-to-speech permission and sets the app name.
3. Connect the phone with USB debugging on (or start an emulator), then `flutter run`.

## Install on your phone without a cable

```powershell
flutter build apk --release
```

Copy `build\app\outputs\flutter-apk\app-release.apk` to the phone and open it.

## German voice for listening

Open Android Settings, search for "Text-to-speech output", and make sure the German
voice is installed. Without it the Hören mocks cannot play (the "Show script" button
is the fallback).

## Change or add content

All content is in `assets/data/` and can be edited without touching Dart code:

- `vocab.txt`: one word per line as `German|English|Urdu`, themes start with `# 5 | Title`
- `lessons/dayNN.json`: grammar, dialogue and questions (`mc`, `fill`, `order`)
- `mocks.json`: Lesen and Hören mocks (`"r": true/false` for richtig/falsch items)
- `writing.json`, `speaking.json`: forms, prompts, cards

After editing run `python tools/validate_data.py` to catch typos before building.
Flashcard progress is keyed by the German text, so do not rename words you already learned.

## Project layout

```
lib/
  main.dart            app start
  app_state.dart       progress, spaced repetition, settings (SharedPreferences)
  models.dart          data classes and answer matching
  data_repo.dart       loads the assets
  tts.dart             German text-to-speech
  theme.dart           colours and theme (der blue, die red, das green)
  widgets.dart         shared widgets
  screens/             one file per area
```
