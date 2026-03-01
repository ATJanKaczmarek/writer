import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/note.dart';
import 'app_event.dart';
import 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  Timer? _saveTimer;

  AppBloc() : super(const AppState()) {
    on<AppFolderOpenRequested>(_onFolderOpenRequested);
    on<AppNoteOpened>(_onNoteOpened);
    on<AppContentChanged>(_onContentChanged);
    on<AppNoteCreated>(_onNoteCreated);
    on<AppPreviewToggled>(_onPreviewToggled);
    on<AppExplorerToggled>(_onExplorerToggled);
    on<AppNotesRefreshRequested>(_onNotesRefreshRequested);
    on<AppThemeToggled>(_onThemeToggled);
    on<AppAcademicModeToggled>(_onAcademicModeToggled);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onFolderOpenRequested(
    AppFolderOpenRequested event,
    Emitter<AppState> emit,
  ) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    final folder = Directory(path);
    emit(state.copyWith(folder: folder, activeNote: null, content: ''));
    await _loadNotes(folder, emit);
  }

  Future<void> _onNoteOpened(
    AppNoteOpened event,
    Emitter<AppState> emit,
  ) async {
    _saveTimer?.cancel();
    // Flush pending changes for the current note before switching.
    if (state.activeNote != null) {
      await state.activeNote!.file.writeAsString(state.content);
    }
    final content = await event.note.file.readAsString();
    emit(state.copyWith(activeNote: event.note, content: content));
  }

  void _onContentChanged(
    AppContentChanged event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(content: event.content));
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _flushSave);
  }

  Future<void> _onNoteCreated(
    AppNoteCreated event,
    Emitter<AppState> emit,
  ) async {
    if (state.folder == null) return;
    final now = DateTime.now();
    final name =
        'note_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.md';
    final file = File('${state.folder!.path}/$name');
    await file.writeAsString('');
    await _loadNotes(state.folder!, emit);
    final note = state.notes.firstWhere(
      (n) => n.file.path == file.path,
      orElse: () => Note(file: file, lastModified: now),
    );
    add(AppNoteOpened(note));
  }

  void _onPreviewToggled(
    AppPreviewToggled event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isPreviewVisible: !state.isPreviewVisible));
  }

  void _onExplorerToggled(
    AppExplorerToggled event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isExplorerCollapsed: !state.isExplorerCollapsed));
  }

  void _onThemeToggled(AppThemeToggled event, Emitter<AppState> emit) {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void _onAcademicModeToggled(
    AppAcademicModeToggled event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isAcademicMode: !state.isAcademicMode));
  }

  Future<void> _onNotesRefreshRequested(
    AppNotesRefreshRequested event,
    Emitter<AppState> emit,
  ) async {
    if (state.folder == null) return;
    await _loadNotes(state.folder!, emit);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadNotes(Directory folder, Emitter<AppState> emit) async {
    final entities = folder.listSync();
    final files = entities
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    final notes = <Note>[];
    for (final file in files) {
      final stat = file.statSync();
      notes.add(Note(file: file, lastModified: stat.modified));
    }
    notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    emit(state.copyWith(notes: notes));
  }

  /// Called by the debounce timer — runs outside an Emitter context so it
  /// dispatches a refresh event after writing instead of emitting directly.
  void _flushSave() {
    if (state.activeNote == null) return;
    state.activeNote!.file.writeAsString(state.content).then((_) {
      add(AppNotesRefreshRequested());
    });
  }

  @override
  Future<void> close() {
    _saveTimer?.cancel();
    return super.close();
  }
}
