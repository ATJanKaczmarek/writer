import '../models/note.dart';
import '../services/grammar_service.dart';

sealed class AppEvent {}

/// User requested to open a folder via the system dialog.
final class AppFolderOpenRequested extends AppEvent {}

/// User tapped a note in the explorer.
final class AppNoteOpened extends AppEvent {
  final Note note;
  AppNoteOpened(this.note);
}

/// Editor text changed (triggers debounced auto-save).
final class AppContentChanged extends AppEvent {
  final String content;
  AppContentChanged(this.content);
}

/// User requested to create a new blank note.
final class AppNoteCreated extends AppEvent {}

/// User toggled the preview panel.
final class AppPreviewToggled extends AppEvent {}

/// User toggled the explorer panel.
final class AppExplorerToggled extends AppEvent {}

/// Internal event emitted after a save to refresh the file list.
final class AppNotesRefreshRequested extends AppEvent {}

/// User toggled dark/light mode.
final class AppThemeToggled extends AppEvent {}

/// User toggled academic writing mode.
final class AppAcademicModeToggled extends AppEvent {}

/// User changed the spell check language.
final class AppLanguageChanged extends AppEvent {
  final String language;
  AppLanguageChanged(this.language);
}

/// Internal event fired when grammar check results are ready.
final class AppGrammarMatchesUpdated extends AppEvent {
  final List<GrammarMatch> matches;
  AppGrammarMatchesUpdated(this.matches);
}

/// Internal event fired on startup to restore the last session.
final class AppSessionLoadRequested extends AppEvent {}
