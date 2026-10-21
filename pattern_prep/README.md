# PatternPrep — DSA Pattern Revision Mobile App

**PatternPrep** is a mobile application built with Flutter, Material 3, and Riverpod designed to help software engineers and students master Data Structures & Algorithms by learning reusable algorithmic patterns, understanding core triggers, studying C++ and Python code templates, and tracking revision schedules efficiently.

---

## 🚀 Phase 1 Implementation Overview

Phase 1 establishes a comprehensive, production-grade frontend architecture with rich local in-memory datasets and reactive state management:

### 1. Architecture & Tech Stack
- **Framework:** Flutter 3.x (Dart 3.x)
- **Design System:** Material 3 with a customized dark & light theme, modern card surfaces, semantic status badges, and responsive typography
- **State Management:** Riverpod 2.6 (`flutter_riverpod`) with custom `Notifier` classes and derived providers
- **Navigation:** `go_router` 14.x with nested shell routes (`ShellRoute`) for persistent bottom navigation and deep-linkable detail pages
- **Data Architecture:** Immutable data models (`Equatable`), repository data fixtures separated from presentation widgets

---

## 📱 Features & Screens

1. **Dashboard (`/dashboard`)**
   - Daily revision goal progress ring and streak tracker
   - Quick action shortcuts (Start Revision, Explore Patterns, Problem List)
   - "Pattern of the Day" showcase card with difficulty badge and quick navigation
   - Overdue / Today revision cards with direct completion toggles
   - Top pattern categories preview

2. **Patterns Directory (`/patterns`)**
   - Search bar with instant real-time filtering across pattern names and concepts
   - Category filter pills (Two Pointers, Sliding Window, Fast & Slow Pointers, Monotonic Stack, Backtracking, etc.)
   - Pattern cards displaying problem counts, mastery status, and bookmark toggles
   - Deep-linked detail view (`/patterns/:id`) featuring:
     - Basic concept explanation & "When to Use" heuristics
     - Step-by-step algorithmic breakdown
     - Time & Space complexity analysis
     - Interactive C++ vs. Python code template switcher with syntax highlighting style and copy button
     - Associated LeetCode-style practice problems checklist
     - Learning status updater (Not Started, In Progress, Mastered) and bookmark action

3. **Problems Checklist (`/problems`)**
   - Searchable problem list with difficulty badges (Easy, Medium, Hard)
   - Bottom sheet multi-filter: Difficulty, Pattern category, and Solved / Unsolved status
   - Interactive checkbox to mark problems as solved with instant state updates
   - External problem link launcher support

4. **Revision Planner (`/revision`)**
   - Spaced repetition workflow organized into **Overdue**, **Today**, and **Upcoming** buckets
   - Direct checkbox toggles to mark revision tasks as completed
   - Quick summary stats of pending vs. completed tasks

5. **More Hub (`/more`)**
   - **Bookmarks (`/bookmarks`):** Quick access to all saved patterns with instant unbookmark capability
   - **Progress & Analytics (`/progress`):** Visual completion metrics, pattern mastery distribution, problem solving rates, and category-level progress bars
   - **Settings (`/settings`):** Theme toggle (Dark / Light mode), default code template language selector (C++ / Python), and daily revision goal slider

---

## 📂 Project Directory Structure

```text
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp with theme config & router
│   ├── router.dart                # GoRouter routing with ShellRoute
│   ├── shell_scaffold.dart        # Bottom navigation bar shell
│   └── theme/
│       ├── app_colors.dart        # Design tokens & color palette
│       └── app_theme.dart         # Material 3 light/dark ThemeData
├── core/
│   ├── providers/
│   │   └── app_providers.dart     # Riverpod state notifiers & derived providers
│   └── widgets/
│       └── shared_widgets.dart    # Reusable cards, tags, badges, empty states
├── features/
│   ├── bookmarks/
│   │   └── presentation/          # Bookmarks screen
│   ├── dashboard/
│   │   └── presentation/          # Dashboard screen & summary widgets
│   ├── more/
│   │   └── presentation/          # More navigation hub
│   ├── patterns/
│   │   ├── data/                  # Pattern sample fixtures
│   │   ├── models/                # Pattern models & complexity types
│   │   └── presentation/          # Pattern list & detail screens
│   ├── problems/
│   │   ├── data/                  # Problem sample fixtures
│   │   ├── models/                # Problem model & difficulty enums
│   │   └── presentation/          # Problems screen & filter sheets
│   ├── progress/
│   │   └── presentation/          # Progress & stats overview screen
│   ├── revision/
│   │   ├── data/                  # Revision task sample fixtures
│   │   ├── models/                # Revision task model & due buckets
│   │   └── presentation/          # Revision planner screen
│   └── settings/
│       └── presentation/          # Settings screen
└── main.dart                      # App entry point with ProviderScope
```

---

## 🧪 Testing & Verification

Run static code analysis:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```
- Includes smoke widget tests for `PatternPrepApp`
- Includes unit tests for `SettingsNotifier`, `PatternsNotifier`, `ProblemsNotifier`, and `RevisionTasksNotifier`
