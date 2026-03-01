import 'dart:io';

import 'package:equatable/equatable.dart';

import '../models/note.dart';

// Sentinel used so copyWith can distinguish "pass null explicitly" vs "omit".
const _absent = Object();

class AppState extends Equatable {
  final Directory? folder;
  final List<Note> notes;
  final Note? activeNote;
  final String content;
  final bool isPreviewVisible;
  final bool isExplorerCollapsed;
  final bool isDarkMode;

  const AppState({
    this.folder,
    this.notes = const [],
    this.activeNote,
    this.content = '',
    this.isPreviewVisible = false,
    this.isExplorerCollapsed = false,
    this.isDarkMode = true,
  });

  AppState copyWith({
    Directory? folder,
    List<Note>? notes,
    Object? activeNote = _absent, // nullable override via sentinel
    String? content,
    bool? isPreviewVisible,
    bool? isExplorerCollapsed,
    bool? isDarkMode,
  }) {
    return AppState(
      folder: folder ?? this.folder,
      notes: notes ?? this.notes,
      activeNote:
          activeNote == _absent ? this.activeNote : activeNote as Note?,
      content: content ?? this.content,
      isPreviewVisible: isPreviewVisible ?? this.isPreviewVisible,
      isExplorerCollapsed: isExplorerCollapsed ?? this.isExplorerCollapsed,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  List<Object?> get props => [
        folder?.path,
        notes,
        activeNote?.path,
        content,
        isPreviewVisible,
        isExplorerCollapsed,
        isDarkMode,
      ];
}
