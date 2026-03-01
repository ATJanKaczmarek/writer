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
          prev.activeNote?.path != curr.activeNote?.path,
      listener: (context, state) {
        final newText = state.content;
        if (_controller.text != newText) {
          _controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
        if (state.activeNote != null) _focusNode.requestFocus();
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
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _editorScroll = ScrollController();
    _gutterScroll = ScrollController();
    _editorScroll.addListener(_syncGutter);
    widget.controller.addListener(_onTextChanged);
    _lineCount = _countLines(widget.controller.text);
  }

  @override
  void dispose() {
    _editorScroll.removeListener(_syncGutter);
    widget.controller.removeListener(_onTextChanged);
    _editorScroll.dispose();
    _gutterScroll.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final count = _countLines(widget.controller.text);
    if (count != _lineCount) setState(() => _lineCount = count);
  }

  void _syncGutter() {
    if (!_gutterScroll.hasClients) return;
    final max = _gutterScroll.position.maxScrollExtent;
    _gutterScroll.jumpTo(_editorScroll.offset.clamp(0.0, max));
  }

  static int _countLines(String text) =>
      text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

  double get _gutterWidth =>
      (_lineCount.toString().length * 9.0 + 32.0).clamp(52.0, 88.0);

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
                itemCount: _lineCount,
                itemExtent: _kLineHeightPx,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    '${i + 1}',
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
            child: CallbackShortcuts(
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
