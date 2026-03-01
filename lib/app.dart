import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'bloc/app_bloc.dart';
import 'screens/editor_screen.dart';

class WriterApp extends StatelessWidget {
  const WriterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        context.select<AppBloc, bool>((b) => b.state.isDarkMode);
    final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    return ShadApp.custom(
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      themeMode: themeMode,
      appBuilder: (context) => MaterialApp(
        title: 'Writer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        home: const EditorScreen(),
      ),
    );
  }
}
