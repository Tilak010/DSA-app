import 'package:flutter/material.dart';

/// PatternPrep design system color tokens.
/// These are fixed constants — do not derive from MaterialColor or user prefs.
abstract final class AppColors {
  // ── Background / Surface ──────────────────────────────────────────────────
  static const Color background = Color(0xFF0B1120);
  static const Color surface = Color(0xFF151E30);
  static const Color surfaceVariant = Color(0xFF1C2840);
  static const Color cardBg = Color(0xFF1A2235);

  // ── Primary / Accent ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFF38BDF8);
  static const Color accent = Color(0xFF818CF8); // indigo accent

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ── Border / Divider ─────────────────────────────────────────────────────
  static const Color border = Color(0xFF293449);
  static const Color divider = Color(0xFF1F2E45);

  // ── Status Colors ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // ── Difficulty Colors ────────────────────────────────────────────────────
  static const Color diffEasy = Color(0xFF22C55E);
  static const Color diffMedium = Color(0xFFF59E0B);
  static const Color diffHard = Color(0xFFEF4444);

  // ── Category chip backgrounds (subtle) ───────────────────────────────────
  static const Color chipBg = Color(0xFF1E3A5F);
  static const Color chipText = Color(0xFF60A5FA);

  // ── Semantic Aliases ─────────────────────────────────────────────────────
  static const Color card = cardBg;
  static const Color cardBorder = border;
  static const Color accentBlue = primary;
  static const Color accentAmber = warning;
  static const Color accentEmerald = success;
}
