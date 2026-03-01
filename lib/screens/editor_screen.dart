import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../bloc/app_bloc.dart';
import '../bloc/app_event.dart';
import '../theme/writer_colors.dart';
import '../widgets/explorer_panel.dart';
import '../widgets/markdown_editor.dart';
import '../widgets/preview_panel.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = WriterColors.of(context);
    return Scaffold(
      backgroundColor: c.appBg,
      body: Column(
        children: [
          const _Toolbar(),
          Divider(height: 1, color: c.divider),
          const Expanded(child: _MainLayout()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar
// ---------------------------------------------------------------------------

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final c = WriterColors.of(context);

    return Container(
      height: 44,
      color: c.appBg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Explorer toggle
          ShadTooltip(
            builder: (_) => Text(state.isExplorerCollapsed
                ? 'Show explorer'
                : 'Hide explorer'),
            child: ShadIconButton.ghost(
              onPressed: () =>
                  context.read<AppBloc>().add(AppExplorerToggled()),
              icon: Icon(
                state.isExplorerCollapsed
                    ? LucideIcons.panelLeftOpen
                    : LucideIcons.panelLeftClose,
                size: 16,
                color: c.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // File title
          Expanded(
            child: Text(
              state.activeNote != null ? state.activeNote!.name : 'Writer',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Theme toggle
          ShadTooltip(
            builder: (_) =>
                Text(state.isDarkMode ? 'Switch to light' : 'Switch to dark'),
            child: ShadIconButton.ghost(
              onPressed: () =>
                  context.read<AppBloc>().add(AppThemeToggled()),
              icon: Icon(
                state.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                size: 16,
                color: c.textMuted,
              ),
            ),
          ),
          // Academic mode toggle
          ShadTooltip(
            builder: (_) => const Text('Academic mode'),
            child: ShadIconButton.ghost(
              onPressed: () =>
                  context.read<AppBloc>().add(AppAcademicModeToggled()),
              icon: Icon(
                LucideIcons.bookOpen,
                size: 14,
                color: state.isAcademicMode ? c.heading : c.textMuted,
              ),
            ),
          ),
          // Preview toggle
          ShadTooltip(
            builder: (_) => Text(
                state.isPreviewVisible ? 'Hide preview' : 'Show preview'),
            child: ShadIconButton.ghost(
              onPressed: () =>
                  context.read<AppBloc>().add(AppPreviewToggled()),
              icon: Icon(
                state.isPreviewVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 16,
                color: state.isPreviewVisible
                    ? c.textSecondary
                    : c.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main layout (Explorer | Editor | Preview)
// ---------------------------------------------------------------------------

class _MainLayout extends StatefulWidget {
  const _MainLayout();

  @override
  State<_MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<_MainLayout> {
  double _explorerWidth = 220;
  double _previewFraction = 0.4;

  static const double _minExplorer = 140;
  static const double _maxExplorer = 360;
  static const double _minPreview = 200;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final c = WriterColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        const handleW = 5.0;
        final totalWidth = constraints.maxWidth;
        final explorerW = state.isExplorerCollapsed
            ? 0.0
            : _explorerWidth.clamp(_minExplorer, _maxExplorer);
        final handlesW = (state.isExplorerCollapsed ? 0.0 : handleW) +
            (state.isPreviewVisible ? handleW : 0.0);
        final remaining = totalWidth - explorerW - handlesW;
        final previewW = state.isPreviewVisible
            ? (remaining * _previewFraction)
                .clamp(_minPreview, remaining - _minPreview)
            : 0.0;
        final editorW = remaining - previewW;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: explorerW,
              child: state.isExplorerCollapsed
                  ? const SizedBox.shrink()
                  : const ExplorerPanel(),
            ),

            if (!state.isExplorerCollapsed)
              _DragHandle(
                color: c.divider,
                hoverColor: c.textDisabled,
                onDrag: (dx) => setState(() {
                  _explorerWidth =
                      (_explorerWidth + dx).clamp(_minExplorer, _maxExplorer);
                }),
              ),

            SizedBox(width: editorW, child: const MarkdownEditor()),

            if (state.isPreviewVisible)
              _DragHandle(
                color: c.divider,
                hoverColor: c.textDisabled,
                onDrag: (dx) => setState(() {
                  final newPreviewW = previewW - dx;
                  _previewFraction = (newPreviewW / remaining)
                      .clamp(_minPreview / remaining, 0.75);
                }),
              ),

            if (state.isPreviewVisible)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: previewW,
                child: const PreviewPanel(),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Drag handle between panels
// ---------------------------------------------------------------------------

class _DragHandle extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final void Function(double dx) onDrag;

  const _DragHandle({
    required this.color,
    required this.hoverColor,
    required this.onDrag,
  });

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 5,
          color: _hovered ? widget.hoverColor : widget.color,
        ),
      ),
    );
  }
}
