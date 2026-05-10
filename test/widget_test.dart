import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salonease/data/providers/auth_provider.dart';
import 'package:salonease/data/services/storage_service.dart';
import 'package:salonease/features/auth/login_screen.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider(create: (_) => AuthProvider(storage)),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('SalonEase'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
