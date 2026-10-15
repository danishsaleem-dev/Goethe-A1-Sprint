import 'package:flutter/material.dart';

import '../widgets.dart';
import 'speaking_screens.dart';
import 'writing_screens.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const PageHeader(title: 'Practice', subtitle: 'Schreiben and Sprechen'),
          const TabBar(
            tabs: [
              Tab(text: 'Writing'),
              Tab(text: 'Speaking'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                WritingTab(),
                SpeakingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
