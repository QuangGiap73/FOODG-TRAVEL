import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_travel/controller/l10n/locale_controller.dart';
import 'package:food_travel/controller/theme_controller.dart';
import 'package:food_travel/main.dart';

void main() {
  testWidgets('MyApp builds with its configured app shell', (tester) async {
    const testHomeKey = Key('test-home');

    await tester.pumpWidget(
      MyApp(
        themeController: ThemeController(),
        localeController: LocaleController(),
        home: const Scaffold(
          key: testHomeKey,
          body: Text('FoodG Travel'),
        ),
      ),
    );
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'FoodG Travel');
    expect(materialApp.supportedLocales, const [Locale('vi'), Locale('en')]);
    expect(find.byKey(testHomeKey), findsOneWidget);
    expect(find.text('FoodG Travel'), findsOneWidget);
  });
}
