import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../bloc/app_bloc.dart';
import '../bloc/app_event.dart';
import '../models/note.dart';
import '../theme/writer_colors.dart';

class ExplorerPanel extends StatelessWidget {
  const ExplorerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final c = WriterColors.of(context);

    return Container(
      color: c.appBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            folderName: state.folder?.uri.pathSegments
                .lastWhere((s) => s.isNotEmpty, orElse: () => ''),
          ),
          Divider(height: 1, color: c.divider),
          Expanded(
            child: state.folder == null
                ? _EmptyState(
                    onOpen: () =>
                        context.read<AppBloc>().add(AppFolderOpenRequested()),
                  )
                : state.notes.isEmpty
                    ? _NoFilesState(
                        onCreate: () =>
                            context.read<AppBloc>().add(AppNoteCreated()),
                      )
                    : _NoteList(
                        notes: state.notes,
                        activeNote: state.activeNote,
                        onTap: (note) =>
                            context.read<AppBloc>().add(AppNoteOpened(note)),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? folderName;
  const _Header({this.folderName});

  @override
  Widget build(BuildContext context) {
    final hasFolder =
        context.select<AppBloc, bool>((b) => b.state.folder != null);
    final c = WriterColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              folderName?.isNotEmpty == true ? folderName! : 'No folder',
              style: TextStyle(
                color: c.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          ShadTooltip(
            builder: (_) => const Text('New note'),
            child: ShadIconButton.ghost(
              onPressed: hasFolder
                  ? () => context.read<AppBloc>().add(AppNoteCreated())
                  : null,
              icon: Icon(LucideIcons.squarePen, size: 14, color: c.textMuted),
            ),
          ),
          ShadTooltip(
            builder: (_) => const Text('Open folder'),
            child: ShadIconButton.ghost(
              onPressed: () =>
                  context.read<AppBloc>().add(AppFolderOpenRequested()),
              icon: Icon(LucideIcons.folderOpen, size: 14, color: c.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onOpen;
  const _EmptyState({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final c = WriterColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.folderOpen, size: 32, color: c.textDisabled),
          const SizedBox(height: 12),
          Text(
            'Open a folder to get started',
            style: TextStyle(color: c.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ShadButton.outline(onPressed: onOpen, child: const Text('Open Folder')),
        ],
      ),
    );
  }
}

class _NoFilesState extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoFilesState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = WriterColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileText, size: 32, color: c.textDisabled),
          const SizedBox(height: 12),
          Text(
            'No markdown files here',
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ShadButton.outline(
              onPressed: onCreate, child: const Text('New Note')),
        ],
      ),
    );
  }
}

class _NoteList extends StatelessWidget {
  final List<Note> notes;
  final Note? activeNote;
  final void Function(Note) onTap;

  const _NoteList({
    required this.notes,
    required this.activeNote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final note = notes[i];
        return _NoteItem(
          note: note,
          isActive: activeNote?.path == note.path,
          onTap: () => onTap(note),
        );
      },
    );
  }
}

class _NoteItem extends StatelessWidget {
  final Note note;
  final bool isActive;
  final VoidCallback onTap;

  const _NoteItem({
    required this.note,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = WriterColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? c.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(
                LucideIcons.fileText,
                size: 14,
                color: isActive ? c.textSecondary : c.textDisabled,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? c.heading : c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
