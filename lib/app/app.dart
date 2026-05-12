import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/theme_provider.dart';
import '../data/services/storage_service.dart';
import 'routes.dart';

class SalonEaseRoot extends StatefulWidget {
  const SalonEaseRoot({super.key});

  @override
  State<SalonEaseRoot> createState() => _SalonEaseRootState();
}

class _SalonEaseRootState extends State<SalonEaseRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final storage = context.read<StorageService>();

    final initialRoute = !storage.hasSeenOnboarding
        ? AppRoutes.onboarding
        : storage.token == null
            ? AppRoutes.login
            : storage.user?.role == 'admin'
                ? AppRoutes.admin
                : AppRoutes.main;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SalonEase',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.themeMode,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: initialRoute,
    );
  }
}
