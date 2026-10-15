import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.init();
  runApp(GermanA1App(state: state));
}

class GermanA1App extends StatelessWidget {
  final AppState state;
  const GermanA1App({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(
        builder: (context) {
          final s = AppScope.of(context);
          return MaterialApp(
            title: 'Deutsch A1',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: s.themeMode,
            home: const Shell(),
          );
        },
      ),
    );
  }
}
