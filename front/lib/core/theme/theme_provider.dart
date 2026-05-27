import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Accent palette enum ──────────────────────────────────────────────────────

enum AccentPalette { rose, champagne, sauge }

// ─── Theme state ─────────────────────────────────────────────────────────────

class ThemeState {
  final ThemeMode mode;
  final AccentPalette accent;

  const ThemeState({
    this.mode = ThemeMode.light,
    this.accent = AccentPalette.rose,
  });

  bool get isDark => mode == ThemeMode.dark;

  ThemeState copyWith({ThemeMode? mode, AccentPalette? accent}) => ThemeState(
    mode: mode ?? this.mode,
    accent: accent ?? this.accent,
  );
}

// ─── Theme notifier ───────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    final accentStr = prefs.getString('accent') ?? 'rose';
    final accent = AccentPalette.values.firstWhere(
      (e) => e.name == accentStr,
      orElse: () => AccentPalette.rose,
    );
    state = ThemeState(
      mode: isDark ? ThemeMode.dark : ThemeMode.light,
      accent: accent,
    );
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = !state.isDark;
    await prefs.setBool('dark_mode', isDark);
    state = state.copyWith(mode: isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setAccent(AccentPalette accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accent', accent.name);
    state = state.copyWith(accent: accent);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
