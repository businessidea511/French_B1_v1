import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/widgets/photo_pages_sheet.dart';

Future<void> _open(WidgetTester tester, PhotoImportMode mode) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () => showPhotoPagesSheet(context, title: 'Add exercises to "Les Métiers"', mode: mode),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exercises-only sheet renders on a phone with submit disabled', (tester) async {
    await _open(tester, PhotoImportMode.exercisesOnly);
    expect(find.textContaining('interactive exercise'), findsOneWidget);
    expect(find.text('No pages yet'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    final submit = find.ancestor(
      of: find.text('Import exercises from 0 pages'),
      matching: find.byWidgetPredicate((w) => w is ElevatedButton),
    );
    expect(submit, findsOneWidget);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
  });

  testWidgets('lesson sheet uses lesson wording', (tester) async {
    await _open(tester, PhotoImportMode.fullLesson);
    expect(find.textContaining('lesson pages in order'), findsOneWidget);
    expect(find.text('Create from 0 pages'), findsOneWidget);
  });
}
