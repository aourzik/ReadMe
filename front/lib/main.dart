import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router.dart';

void main() {
  runApp(const ProviderScope(child: ReadMeApp()));
}

class ReadMeApp extends ConsumerWidget {
  const ReadMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final router     = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ReadMe',
      debugShowCheckedModeBanner: false,
      theme:     AppTheme.light(),
      darkTheme:  AppTheme.dark(),
      themeMode:  themeState.mode,
      routerConfig: router,
    );
  }
}
