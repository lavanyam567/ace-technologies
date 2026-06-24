// Basic widget test for Ace Technologies app

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ace_technologies/main.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AceTechnologiesApp()));
    await tester.pump(const Duration(seconds: 1));

    // Verify that the app loads with the main navigation.
    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Products'), findsAtLeastNWidgets(1));
    expect(find.text('Services'), findsAtLeastNWidgets(1));
    expect(find.text('Cart'), findsAtLeastNWidgets(1));
    expect(find.text('Account'), findsAtLeastNWidgets(1));
  });
}
