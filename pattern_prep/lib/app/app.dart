import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PatternPrepApp extends ConsumerWidget {
  const PatternPrepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(settingsProvider).isDarkMode;

    return MaterialApp.router(
      title: 'PatternPrep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
