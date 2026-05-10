import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/booking_provider.dart';
import 'data/providers/service_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/providers/wishlist_provider.dart';
import 'data/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => AuthProvider(storage)),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider(storage)),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: const SalonEaseRoot(),
    ),
  );
}

