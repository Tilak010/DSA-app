import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/theme/app_colors.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  static const _destinations = [
    _NavDest(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      path: '/home',
    ),
    _NavDest(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Patterns',
      path: '/patterns',
    ),
    _NavDest(
      icon: Icons.event_repeat_outlined,
      activeIcon: Icons.event_repeat_rounded,
      label: 'Revision',
      path: '/revision',
    ),
    _NavDest(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Progress',
      path: '/progress',
    ),
    _NavDest(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      path: '/settings',
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.go(_destinations[i].path),
          destinations: _destinations.map((d) => NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.activeIcon),
            label: d.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _NavDest {
  const _NavDest({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}
