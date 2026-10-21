import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/patterns/presentation/patterns_screen.dart';
import '../features/patterns/presentation/pattern_detail_screen.dart';
import '../features/revision/presentation/revision_screen.dart';
import '../features/revision/presentation/quick_revision_screen.dart';
import '../features/revision/presentation/revision_history_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/patterns',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PatternsScreen(),
          ),
        ),
        GoRoute(
          path: '/revision',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RevisionScreen(),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProgressScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    // Full-screen routes (outside shell)
    GoRoute(
      path: '/patterns/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PatternDetailScreen(patternId: id);
      },
    ),
    GoRoute(
      path: '/patterns/:id/quick-review',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return QuickRevisionScreen(patternId: id);
      },
    ),
    GoRoute(
      path: '/bookmarks',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BookmarksScreen(),
    ),
    GoRoute(
      path: '/progress/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RevisionHistoryScreen(),
    ),
  ],
);
