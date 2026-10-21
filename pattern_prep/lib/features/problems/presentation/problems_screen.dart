import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';

/// Deprecated: Problem-solving platform elements have been removed
/// in accordance with Phase 2 specifications prioritizing Pattern Revision.
class ProblemsScreen extends StatelessWidget {
  const ProblemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patterns Focus'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'PatternPrep is now focused on Pattern Revision',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the Patterns and Revision sections to revise concepts, checklists, and templates.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/patterns'),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Explore Patterns'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
