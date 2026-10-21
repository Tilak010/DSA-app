import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pattern_prep/core/providers/app_providers.dart';
import 'package:pattern_prep/features/patterns/models/pattern_model.dart';
import 'package:pattern_prep/features/revision/presentation/quick_revision_screen.dart';
import 'package:pattern_prep/features/revision/presentation/revision_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Full Revision Session Flow: Intro -> Recall -> Reveal -> Checklist -> Rating -> Summary',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state: ensure pattern exists
    const patternId = 'two_pointers';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: QuickRevisionScreen(patternId: patternId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ── STEP 1: Introduction ──
    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('Step 1: Introduction'), findsOneWidget);
    expect(find.text('Two Pointers'), findsWidgets);

    // Tap Next Step -> Step 2
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    // ── STEP 2: Quick Recall ──
    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.text('Step 2: Quick Recall'), findsOneWidget);
    expect(find.text('Explain the pattern in your own words.'), findsOneWidget);

    // Tap Next Step -> Step 3
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    // ── STEP 3: Reveal Answers ──
    expect(find.text('Step 3 of 6'), findsOneWidget);
    expect(find.text('Step 3: Reveal Answers'), findsOneWidget);
    expect(find.text('Core Idea & Intuition'), findsOneWidget);

    // Tap Reveal All
    await tester.tap(find.text('Reveal All'));
    await tester.pumpAndSettle();
    expect(find.text('Time & Space Complexity'), findsOneWidget);

    // Tap Next Step -> Step 4
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    // ── STEP 4: Checklist ──
    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('Step 4: Checklist'), findsOneWidget);
    expect(find.text('Revision Checklist'), findsOneWidget);

    // Toggle a checklist item
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsWidgets);
    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();

    // Proceed to Rating -> Step 5
    await tester.tap(find.text('Proceed to Rating'));
    await tester.pumpAndSettle();

    // ── STEP 5: Confidence Rating ──
    expect(find.text('Step 5 of 6'), findsOneWidget);
    expect(find.text('Step 5: Confidence Rating'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);

    // Tap 'Good' rating card
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    // ── STEP 6: Session Summary ──
    expect(find.text('Step 6 of 6'), findsOneWidget);
    expect(find.text('Revision Session Completed!'), findsOneWidget);
    expect(find.text('Session Breakdown'), findsOneWidget);
    expect(find.text('Finish Session & Return to Planner'), findsOneWidget);

    // Verify pattern state in repository
    final pattern = container.read(patternDetailsProvider).firstWhere((p) => p.id == patternId);
    expect(pattern.lastConfidence, equals(RevisionConfidence.good));
    expect(pattern.nextReviewDate, isNotNull);
  });

  testWidgets('Revision Screen renders tabs and real counts from providers', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: RevisionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Revision Planner'), findsOneWidget);
    expect(find.text("Today's Revision Goal"), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });
}
