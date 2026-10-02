import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/pages/listening/listening_page.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('long topic names stay inside the dropdown on a phone in Arabic', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language': 'ar'});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: ListeningPage())),
    ));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Daily Routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dialogue: Louer un logement (Client/Agence)').last);
    await tester.pumpAndSettle();

    // No "RenderFlex overflowed" error, and the chosen title is drawn inside the screen.
    expect(tester.takeException(), isNull);
    final box = tester.getRect(find.text('Dialogue: Louer un logement (Client/Agence)').first);
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(360));
  });
}
