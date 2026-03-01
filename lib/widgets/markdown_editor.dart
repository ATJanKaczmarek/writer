import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/app_bloc.dart';
import '../bloc/app_event.dart';
import '../bloc/app_state.dart';
import '../controllers/markdown_controller.dart';
import '../theme/writer_colors.dart';

const _kFontFamily = 'FiraCode';
const _kFontSize = 15.0;
const _kLineHeight = 1.65;
const _kLineHeightPx = _kFontSize * _kLineHeight; // 24.75 px
const _kTopPadding = 32.0;
const _kBottomPadding = 32.0;

// Horizontal content padding inside the TextField (left 16 + right 32).
const _kEditorHPadding = 48.0;

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key});

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final MarkdownEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = MarkdownEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    context.read<AppBloc>().add(AppContentChanged(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listenWhen: (prev, curr) =>
          prev.activeNote?.path != curr.activeNote?.path ||
          prev.grammarMatches != curr.grammarMatches,
      listener: (context, state) {
        final newText = state.content;
        if (_controller.text != newText) {
          _controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
        _controller.grammarMatches = state.grammarMatches;
        _controller.invalidate();
        if (state.activeNote != null &&
            FocusScope.of(context).focusedChild == null) {
          _focusNode.requestFocus();
        }
      },
      child: BlocBuilder<AppBloc, AppState>(
        buildWhen: (prev, curr) =>
            prev.activeNote?.path != curr.activeNote?.path,
        builder: (context, state) {
          if (state.activeNote == null) return const _NoFileOpen();
          return _EditorWithLineNumbers(
            controller: _controller,
            focusNode: _focusNode,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor + line-number gutter
// ---------------------------------------------------------------------------

class _EditorWithLineNumbers extends StatefulWidget {
  final MarkdownEditingController controller;
  final FocusNode focusNode;

  const _EditorWithLineNumbers({
    required this.controller,
    required this.focusNode,
  });

  @override
  State<_EditorWithLineNumbers> createState() =>
      _EditorWithLineNumbersState();
}

class _EditorWithLineNumbersState extends State<_EditorWithLineNumbers> {
  late final ScrollController _editorScroll;
  late final ScrollController _gutterScroll;

  /// One entry per *visual* row.
  /// - An `int` is the 1-based logical line number shown on the first visual
  ///   row of that logical line.
  /// - `null` marks a soft-wrapped continuation row: the gutter shows blank.
  List<int?> _gutterLabels = const [1];

  /// Number of logical lines — used only to size the gutter width.
  int _logicalLineCount = 1;

  /// Pixel width available for text inside the TextField (excluding horizontal
  /// content padding). Set by LayoutBuilder; stays 0 until first layout.
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    _editorScroll = ScrollController();
    _gutterScroll = ScrollController();
    _editorScroll.addListener(_syncGutter);
    widget.controller.addListener(_onTextChanged);
    _logicalLineCount = _countLogicalLines(widget.controller.text);
  }

  @override
  void dispose() {
    _editorScroll.removeListener(_syncGutter);
    widget.controller.removeListener(_onTextChanged);
    _editorScroll.dispose();
    _gutterScroll.dispose();
    super.dispose();
  }

  // ---- text / width change handlers ----

  void _onTextChanged() => _update(widget.controller.text, _textWidth);

  void _onEditorWidth(double width) {
    if (width == _textWidth) return;
    _textWidth = width;
    _update(widget.controller.text, width);
  }

  // ---- core recompute ----

  void _update(String text, double textWidth) {
    final count = _countLogicalLines(text);
    final labels = textWidth > 0
        ? _computeGutterLabels(text, textWidth)
        : List<int?>.generate(count, (i) => i + 1);

    if (count != _logicalLineCount || labels.length != _gutterLabels.length) {
      setState(() {
        _logicalLineCount = count;
        _gutterLabels = labels;
      });
    }
  }

  // ---- scroll sync ----

  void _syncGutter() {
    if (!_gutterScroll.hasClients) return;
    final max = _gutterScroll.position.maxScrollExtent;
    _gutterScroll.jumpTo(_editorScroll.offset.clamp(0.0, max));
  }

  // ---- helpers ----

  static int _countLogicalLines(String text) =>
      text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

  /// Builds a flat list of gutter labels, one entry per visual row.
  ///
  /// Uses [TextPainter.computeLineMetrics] to count how many visual rows each
  /// logical line occupies when constrained to [textWidth]. The first visual
  /// row of a logical line carries its 1-based number; continuation (wrapped)
  /// rows are `null` so the gutter renders them blank.
  static List<int?> _computeGutterLabels(String text, double textWidth) {
    const style = TextStyle(
      fontFamily: _kFontFamily,
      fontSize: _kFontSize,
      height: _kLineHeight,
    );

    final lines = text.isEmpty ? const [''] : text.split('\n');
    final labels = <int?>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final int visualRows;

      if (line.isEmpty) {
        visualRows = 1;
      } else {
        final painter = TextPainter(
          text: TextSpan(text: line, style: style),
          textDirection: TextDirection.ltr,
        );
        painter.layout(maxWidth: textWidth);
        visualRows = painter.computeLineMetrics().length;
      }

      labels.add(i + 1); // first visual row: logical line number
      for (var r = 1; r < visualRows; r++) {
        labels.add(null); // continuation rows: blank
      }
    }

    return labels;
  }

  double get _gutterWidth =>
      (_logicalLineCount.toString().length * 9.0 + 32.0).clamp(52.0, 88.0);

  @override
  Widget build(BuildContext context) {
    final c = WriterColors.of(context);

    return Container(
      color: c.editorBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Gutter ----
          SizedBox(
            width: _gutterWidth,
            child: Container(
              color: c.gutterBg,
              child: ListView.builder(
                controller: _gutterScroll,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: _kTopPadding,
                  bottom: _kBottomPadding,
                ),
                itemCount: _gutterLabels.length,
                itemExtent: _kLineHeightPx,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    _gutterLabels[i]?.toString() ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: _kFontSize,
                      height: _kLineHeight,
                      color: c.lineNumber,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---- Separator ----
          Container(width: 1, color: c.divider),

          // ---- Editor ----
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final newTextWidth = constraints.maxWidth - _kEditorHPadding;
                if (newTextWidth > 0 && newTextWidth != _textWidth) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _onEditorWidth(newTextWidth);
                  });
                }
                return CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
                        () {},
                  },
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    scrollController: _editorScroll,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: _kFontSize,
                      height: _kLineHeight,
                      color: c.textPrimary,
                    ),
                    cursorColor: c.cursor,
                    cursorWidth: 2,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(
                        16, _kTopPadding, 32, _kBottomPadding,
                      ),
                      isDense: false,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _NoFileOpen extends StatelessWidget {
  const _NoFileOpen();

  @override
  Widget build(BuildContext context) {
    final c = WriterColors.of(context);
    return Container(
      color: c.editorBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 48, color: c.divider),
            const SizedBox(height: 16),
            Text(
              'Select a note to start writing',
              style: TextStyle(color: c.textDisabled, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
