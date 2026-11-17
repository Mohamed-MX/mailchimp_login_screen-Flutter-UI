import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailchimp_login_screen_flutter_ui/main.dart';
import 'package:mailchimp_login_screen_flutter_ui/campaign/campaign_services.dart';
import 'package:mailchimp_login_screen_flutter_ui/campaign/screens/campaign_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Login test with mx / mx and navigation smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify login screen elements exist
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Username or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    final textFields = find.byType(TextFormField);

    // Enter wrong credentials
    await tester.enterText(textFields.at(0), 'wrong');
    await tester.enterText(textFields.at(1), 'wrong');
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Invalid username or password'), findsWidgets);

    // Enter correct credentials 'mx' and 'mx'
    await tester.enterText(textFields.at(0), 'mx');
    await tester.enterText(textFields.at(1), 'mx');
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    // Verify navigation to HomeScreen
    expect(find.text('Campaigns & Notes'), findsOneWidget);
    expect(find.text('New Campaign'), findsOneWidget);
  });

  testWidgets('CampaignScreen add blocks and swap text/image test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CampaignScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Campaign'), findsOneWidget);
    expect(find.text('CAMPAIGN BLOCKS'), findsOneWidget);
    expect(find.text('Image + Text'), findsOneWidget);
    expect(find.text('Just Text'), findsOneWidget);
    expect(find.text('Just Image'), findsOneWidget);

    // Add a Just Text block
    await tester.tap(find.text('Just Text'));
    await tester.pumpAndSettle();
    expect(find.text('Just Text Block'), findsOneWidget);

    // Add a Just Image block
    await tester.tap(find.text('Just Image'));
    await tester.pumpAndSettle();
    expect(find.text('Just Image Block'), findsOneWidget);

    // Verify swap button works for Image & Text block
    final swapButton = find.byTooltip('Swap text and image sides');
    expect(swapButton, findsOneWidget);
    await tester.tap(swapButton);
    await tester.pumpAndSettle();

    // Tap on image placeholder to verify options modal
    final imagePlaceholder = find.text('Click to add image').first;
    await tester.tap(imagePlaceholder);
    await tester.pumpAndSettle();

    expect(find.text('Select Image Option'), findsOneWidget);
    expect(find.text('Option 1: Online Image'), findsOneWidget);
    expect(find.text('Option 2: File Picker'), findsOneWidget);
  });
}
