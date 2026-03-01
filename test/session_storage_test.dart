import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writer/bloc/app_bloc.dart';
import 'package:writer/bloc/app_event.dart';
import 'package:writer/bloc/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session storage — restore preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('fresh start: defaults are applied when no prefs saved', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = AppBloc();
      // Wait for the session load to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final s = bloc.state;
      expect(s.isDarkMode, true);
      expect(s.isPreviewVisible, false);
      expect(s.isExplorerCollapsed, false);
      expect(s.isAcademicMode, false);
      expect(s.folder, isNull);
      expect(s.activeNote, isNull);
      await bloc.close();
    });

    test('saved bool preferences are restored on load', () async {
      SharedPreferences.setMockInitialValues({
        'isDarkMode': false,
        'isPreviewVisible': true,
        'isExplorerCollapsed': true,
        'isAcademicMode': true,
        'folderPath': '',
        'notePath': '',
      });
      final bloc = AppBloc();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final s = bloc.state;
      expect(s.isDarkMode, false);
      expect(s.isPreviewVisible, true);
      expect(s.isExplorerCollapsed, true);
      expect(s.isAcademicMode, true);
      await bloc.close();
    });

    test('missing/deleted folder is handled gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'folderPath': '/nonexistent/path/that/does/not/exist',
        'notePath': '/nonexistent/path/that/does/not/exist/note.md',
      });
      final bloc = AppBloc();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final s = bloc.state;
      // Folder should not be set since directory doesn't exist
      expect(s.folder, isNull);
      expect(s.activeNote, isNull);
      await bloc.close();
    });

    test('saved folder path that exists is restored', () async {
      // Use a temp directory that actually exists
      final dir = await Directory.systemTemp.createTemp('writer_test_');
      try {
        SharedPreferences.setMockInitialValues({
          'folderPath': dir.path,
          'notePath': '',
        });
        final bloc = AppBloc();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final s = bloc.state;
        expect(s.folder?.path, dir.path);
        expect(s.notes, isEmpty); // No .md files created
        await bloc.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('active note is restored when folder and note file exist', () async {
      final dir = await Directory.systemTemp.createTemp('writer_test_');
      try {
        final noteFile = File('${dir.path}/test_note.md');
        await noteFile.writeAsString('# Hello\n\nContent.');

        SharedPreferences.setMockInitialValues({
          'folderPath': dir.path,
          'notePath': noteFile.path,
        });
        final bloc = AppBloc();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final s = bloc.state;
        expect(s.folder?.path, dir.path);
        expect(s.activeNote?.file.path, noteFile.path);
        expect(s.content, '# Hello\n\nContent.');
        await bloc.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('note path that no longer exists is skipped gracefully', () async {
      final dir = await Directory.systemTemp.createTemp('writer_test_');
      try {
        SharedPreferences.setMockInitialValues({
          'folderPath': dir.path,
          'notePath': '${dir.path}/deleted_note.md',
        });
        final bloc = AppBloc();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final s = bloc.state;
        expect(s.folder?.path, dir.path);
        expect(s.activeNote, isNull);
        await bloc.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('Session storage — persist on toggle', () {
    late AppBloc bloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      bloc = AppBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('AppPreviewToggled persists isPreviewVisible', () async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc.add(AppPreviewToggled());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isPreviewVisible'), true);
    });

    test('AppExplorerToggled persists isExplorerCollapsed', () async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc.add(AppExplorerToggled());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isExplorerCollapsed'), true);
    });

    test('AppThemeToggled persists isDarkMode', () async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc.add(AppThemeToggled());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isDarkMode'), false); // was true, now false
    });

    test('AppAcademicModeToggled persists isAcademicMode', () async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc.add(AppAcademicModeToggled());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isAcademicMode'), true);
    });
  });

  group('AppState', () {
    test('copyWith preserves all fields when no args given', () {
      const s = AppState(
        isDarkMode: false,
        isPreviewVisible: true,
        isExplorerCollapsed: true,
        isAcademicMode: true,
        content: 'hello',
      );
      final copy = s.copyWith();
      expect(copy.isDarkMode, false);
      expect(copy.isPreviewVisible, true);
      expect(copy.isExplorerCollapsed, true);
      expect(copy.isAcademicMode, true);
      expect(copy.content, 'hello');
    });
  });
}
