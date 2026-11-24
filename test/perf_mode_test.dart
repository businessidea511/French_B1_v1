import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/services/perf_mode.dart';
import 'package:french_course_b1/widgets/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PerfMode.instance.reset();
  });
  tearDown(() => PerfMode.instance.reset());

  test('light design is the default; only an explicit "full" keeps the effects', () async {
    final perf = PerfMode.instance;
    expect(perf.isLight, isTrue);

    await perf.set(PerfMode.off);
    expect(perf.isLight, isFalse, reason: 'the learner asked for full effects');
    perf.reset();
    await perf.load();
    expect(perf.choice, PerfMode.off, reason: 'the choice is remembered');

    // A phone that kept the old "auto" choice gets the light design.
    SharedPreferences.setMockInitialValues({'perf_mode': 'auto'});
    perf.reset();
    await perf.load();
    expect(perf.isLight, isTrue);
  });

  testWidgets('fast mode: no entrance animation, still background', (tester) async {
    PerfMode.instance.choice = PerfMode.on;
    await tester.pumpWidget(const MaterialApp(
      home: AuroraBackground(child: Entrance(index: 3, child: Text('Bonjour'))),
    ));
    // Visible at once, and nothing keeps redrawing.
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('full effects: the card swings in', (tester) async {
    PerfMode.instance.choice = PerfMode.off;
    await tester.pumpWidget(const MaterialApp(home: Entrance(child: Text('Bonjour'))));
    expect(find.byType(Opacity), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
