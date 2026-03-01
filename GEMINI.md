# Writer Project Overview

Writer is a minimalistic, high-performance Markdown writing application built for macOS using Flutter. It features a three-pane layout: a collapsible file explorer (left), a custom-built monospace markdown editor with syntax highlighting (center), and a toggleable live Markdown preview (right).

**Note:** Always check `CLAUDE.md` for any additional or updated guidance as it is also used by other agents in this repository.

## Core Technologies
- **Framework:** [Flutter](https://flutter.dev) (Targeting macOS)
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) 8.x
- **UI Components:** [Shadcn UI for Flutter](https://pub.dev/packages/shadcn_ui) v0.26.x
- **Markdown Rendering:** [flutter_markdown](https://pub.dev/packages/flutter_markdown)
- **Typography:** Fira Code (included in `assets/fonts/`)

## Architecture & Structure
The project follows a standard Flutter architectural pattern with a clear separation between business logic and UI.

### Key Files & Directories
- `lib/main.dart`: Entry point; creates `AppBloc` via `BlocProvider`.
- `lib/app.dart`: `ShadApp.custom` wrapping `MaterialApp`.
- `lib/bloc/`: Central brain of the application.
    - `app_event.dart`: Sealed event hierarchy (e.g., `AppFolderOpenRequested`, `AppNoteOpened`, `AppContentChanged`, `AppThemeToggled`).
    - `app_state.dart`: Immutable `AppState` (Equatable) with `copyWith`. `isDarkMode` defaults to true.
    - `app_bloc.dart`: Handles async logic and debounced auto-save timer.
- `lib/models/note.dart`: `Note` model representing a local Markdown file (File + lastModified).
- `lib/screens/editor_screen.dart`: Main workspace layout with draggable panel dividers and toolbar.
- `lib/widgets/`: Core UI components:
    - `explorer_panel.dart`: Sidebar for navigating Markdown files.
    - `markdown_editor.dart`: Writing area with line numbers. Uses `_syncGutter()` to align line numbers and `_EditorWithLineNumbers` for efficiency.
    - `preview_panel.dart`: Live rendering using `context.select` to minimize rebuilds.
- `lib/controllers/markdown_controller.dart`: `TextEditingController` subclass overriding `buildTextSpan` for real-time regex-based syntax highlighting.
- `lib/theme/writer_colors.dart`: Resolves semantic color tokens via `Theme.of(context).brightness`.

## Key Features
- **Folder-based Workflow:** Users open a local directory to manage all Markdown files within it.
- **Custom Markdown Editor:** Features line numbers, monospace font support, and basic syntax highlighting in the edit view.
- **Auto-save:** Implements a debounce timer (600ms) that automatically saves changes to the local file system.
- **Live Preview:** Real-time rendering of Markdown content in a dedicated panel.
- **Responsive Layout:** Draggable handles allow resizing the explorer and preview panels.
- **Theme Support:** Native light and dark mode toggling.

## Building and Running
Ensure you have the Flutter SDK installed and configured for macOS development.

### Development Commands
- **Run the app:** `flutter run -d macos`
- **Run tests:** `flutter test`
- **Build for macOS:** `flutter build macos`
- **Get dependencies:** `flutter pub get`
- **Analyze code:** `flutter analyze`

## Workflow Requirements
- **Branching**: Develop each feature or fix in its own dedicated branch.
- **Commits**: Use conventional commits with scopes and gitmojis (e.g., `feat(editor): ✨ add line numbers`). Commits are an integral part of the implementation process.
- **Tests**: Every new feature must have corresponding tests. Update affected tests when changing existing behavior. Run `flutter test` to verify.
- **Verification**: Track each change and manually verify. Use `flutter analyze` + `flutter build macos --debug` as a minimum gate.

## Development Conventions

### State Management
- Always use `AppBloc` for global application state. Do not introduce local state for cross-cutting concerns.
- Widgets read state with `context.watch<AppBloc>().state` or `context.select<AppBloc, T>()` and dispatch events with `context.read<AppBloc>().add(SomeEvent())`.
- `BlocBuilder` should use `buildWhen` where appropriate to optimize rebuilds.

### Styling & Theming
- All colors MUST come from `WriterColors.of(context)`. Never hardcode colors in widgets.
- Use `ShadApp.custom(appBuilder:)` and `ShadIconButton.ghost`. Avoid deprecated `ShadApp.material`.
- `app.dart` reads `isDarkMode` from `AppBloc` and passes `themeMode` to both `ShadApp.custom` and `MaterialApp`.

### Editor & Typography
- Font: FiraCode (`assets/fonts/`). All editor and code text uses `fontFamily: 'FiraCode'`.
- **Syntax Highlighting**: Purely regex-based inside `MarkdownEditingController`. Headings use bold+color ONLY — **no fontSize change** — to maintain line-number alignment and fixed line height.
- **Auto-save**: `AppContentChanged` updates state; a 600ms debounce timer in `AppBloc` calls `_flushSave()`.

### File Operations & Security
- All I/O should be handled within the `AppBloc` to maintain a single source of truth for the file system state.
- macOS sandbox entitlements (`com.apple.security.files.user-selected.read-write`) are in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
