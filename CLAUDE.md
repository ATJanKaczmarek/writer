# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Minimalistic macOS markdown writing app built with Flutter. Three-panel layout: collapsible file explorer (left), monospace markdown editor with syntax highlighting (center), toggleable preview (right).

## Commands

```bash
flutter run -d macos          # Run in debug mode
flutter build macos           # Release build
flutter analyze               # Static analysis
flutter test                  # Run tests
```

## Architecture

```
lib/
  main.dart                        # Entry point; creates AppBloc via BlocProvider
  app.dart                         # ShadApp.custom wrapping MaterialApp
  models/note.dart                 # Note model (File + lastModified)
  bloc/
    app_event.dart                 # Sealed event hierarchy (AppFolderOpenRequested,
                                   #   AppNoteOpened, AppContentChanged, AppNoteCreated,
                                   #   AppPreviewToggled, AppExplorerToggled,
                                   #   AppNotesRefreshRequested, AppThemeToggled)
    app_state.dart                 # Immutable AppState (Equatable) with copyWith;
                                   #   nullable fields use an _absent sentinel;
                                   #   isDarkMode defaults to true
    app_bloc.dart                  # AppBloc: all async handlers + debounced auto-save
                                   #   timer; _flushSave() dispatches a refresh event
                                   #   since it runs outside an Emitter context
  theme/
    writer_colors.dart             # WriterColors.of(context) resolves dark/light
                                   #   palette via Theme.of(context).brightness;
                                   #   all semantic colour tokens live here
  controllers/
    markdown_controller.dart       # TextEditingController subclass overriding
                                   #   buildTextSpan for live MD syntax highlighting
  screens/
    editor_screen.dart             # Root scaffold: _Toolbar + _MainLayout with
                                   #   draggable panel dividers
  widgets/
    explorer_panel.dart            # Left panel; dispatches AppFolderOpenRequested /
                                   #   AppNoteOpened / AppNoteCreated
    markdown_editor.dart           # BlocListener syncs controller on note change;
                                   #   BlocBuilder only rebuilds on note switch;
                                   #   text changes dispatch AppContentChanged.
                                   #   _EditorWithLineNumbers: gutter ListView
                                   #   (NeverScrollableScrollPhysics) is scroll-synced
                                   #   to the TextField via _syncGutter(); line count
                                   #   tracked in state, rebuilds only on \n changes.
                                   #   _k* constants define shared font metrics.
    preview_panel.dart             # context.select on content to minimise rebuilds;
                                   #   flutter_markdown rendered view
```

## Workflow Requirements

- **Branching**: develop each feature or fix in its own dedicated branch.
- **Commits**: use conventional commits with scopes and gitmojis (e.g., `feat(editor): ✨ add line numbers`). Commits are an integral part of the implementation process.
- **Tests**: every new feature must have corresponding tests; when changing existing behaviour, update the affected tests before finishing. Run `flutter test` to verify.
- **Verification**: after implementing a feature, track each change made and manually verify each one works before considering the task done. Use `flutter analyze` + `flutter build macos --debug` as a minimum gate.

## Key Conventions

- **State management**: flutter_bloc 8.x. All state lives in `AppBloc`. Widgets read state with `context.watch<AppBloc>().state` or `context.select<AppBloc, T>()` and dispatch events with `context.read<AppBloc>().add(SomeEvent())`.
- **Rebuild optimisation**: `BlocBuilder` uses `buildWhen`, and `PreviewPanel` uses `context.select`, so widgets only rebuild for the slice of state they actually need.
- **shadcn_ui v0.26.x**: use `ShadApp.custom(appBuilder:)` and `ShadIconButton.ghost` — the older `ShadApp.material` and `icon:` param on `ShadButton` are deprecated.
- **Theming**: all colours come from `WriterColors.of(context)` — never hardcode colours in widgets. `app.dart` reads `isDarkMode` from `AppBloc` and passes `themeMode` to both `ShadApp.custom` and the inner `MaterialApp`. Toggle is dispatched via `AppThemeToggled`.
- **Font**: FiraCode (`assets/fonts/`). All editor and code text uses `fontFamily: 'FiraCode'`. The constant `_kFontFamily = 'FiraCode'` is defined in `markdown_editor.dart`.
- **Auto-save**: `AppContentChanged` updates state immediately; a 600 ms debounce timer in `AppBloc` then calls `_flushSave()` which writes to disk and fires `AppNotesRefreshRequested`.
- **Syntax highlighting**: purely regex-based inside `MarkdownEditingController`. Block patterns (headings, blockquotes, lists, HR) process line-by-line; inline patterns (bold, italic, code, links) run over the full text. Overlapping tokens resolved by skipping any whose start < current cursor. Headings use bold+colour only — **no fontSize change** — so every line stays `_kLineHeightPx` tall and line-number alignment is preserved.
- macOS sandbox entitlements (`com.apple.security.files.user-selected.read-write`) are in both `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.

## Planned Features

