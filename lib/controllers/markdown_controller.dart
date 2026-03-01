import 'package:flutter/material.dart';

import '../theme/writer_colors.dart';

class MarkdownEditingController extends TextEditingController {
  // Regex patterns — order matters: fenced code before inline code,
  // bold+italic before bold, bold before italic.
  static final List<(RegExp, TextStyle? Function(WriterColors))>
      _inlineStylePatterns = [
    (
      RegExp(r'```[\s\S]*?```', multiLine: true),
      (c) => TextStyle(
            fontFamily: 'FiraCode',
            color: c.code,
            backgroundColor: c.codeBg,
          ),
    ),
    (
      RegExp(r'\*\*\*[^*\n]+\*\*\*'),
      (c) => TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: c.bold,
          ),
    ),
    (
      RegExp(r'\*\*[^*\n]+\*\*|__[^_\n]+__'),
      (c) => TextStyle(fontWeight: FontWeight.bold, color: c.bold),
    ),
    (
      RegExp(r'\*[^*\n]+\*|_[^_\n]+_'),
      (c) => TextStyle(fontStyle: FontStyle.italic, color: c.italic),
    ),
    (
      RegExp(r'`[^`\n]+`'),
      (c) => TextStyle(
            fontFamily: 'FiraCode',
            color: c.code,
            backgroundColor: c.codeBg,
          ),
    ),
    (
      RegExp(r'\[[^\]\n]+\]\([^)\n]+\)'),
      (c) => TextStyle(
            color: c.link,
            decoration: TextDecoration.underline,
            decorationColor: c.link,
          ),
    ),
  ];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final colors = WriterColors.of(context);
    final text = value.text;
    if (text.isEmpty) return TextSpan(text: text, style: style);

    final base = (style ?? const TextStyle()).copyWith(color: colors.textPrimary);

    if (value.composing.isValid && withComposing) {
      final composingStyle =
          base.merge(const TextStyle(decoration: TextDecoration.underline));
      return TextSpan(style: base, children: [
        _highlighted(value.composing.textBefore(text), base, colors),
        TextSpan(
            style: composingStyle,
            text: value.composing.textInside(text)),
        _highlighted(value.composing.textAfter(text), base, colors),
      ]);
    }

    return _highlighted(text, base, colors);
  }

  TextSpan _highlighted(String text, TextStyle base, WriterColors colors) {
    if (text.isEmpty) return TextSpan(text: '', style: base);

    final tokens = <_Token>[];
    _collectBlockTokens(text, tokens, colors);
    _collectInlineTokens(text, tokens, colors);

    tokens.sort((a, b) {
      final c = a.start.compareTo(b.start);
      return c != 0 ? c : b.end.compareTo(a.end);
    });

    return TextSpan(style: base, children: _buildSpans(text, tokens, base));
  }

  void _collectBlockTokens(
      String text, List<_Token> out, WriterColors colors) {
    int offset = 0;
    for (final line in text.split('\n')) {
      _processLine(line, offset, out, colors);
      offset += line.length + 1;
    }
  }

  void _processLine(
      String line, int offset, List<_Token> out, WriterColors colors) {
    // Headings — bold + colour only, no fontSize change (preserves line height)
    final headingMatch = RegExp(r'^(#{1,6})( .*)$').firstMatch(line);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      final markerEnd = offset + level + 1;
      final markerOpacity = (0.6 - (level - 1) * 0.06).clamp(0.3, 0.6);
      out.add(_Token(offset, markerEnd,
          TextStyle(color: colors.marker.withValues(alpha: markerOpacity))));
      out.add(_Token(
        markerEnd,
        offset + line.length,
        TextStyle(color: colors.heading, fontWeight: FontWeight.bold),
      ));
      return;
    }

    // Horizontal rule
    if (RegExp(r'^[-*_]{3,}\s*$').hasMatch(line)) {
      out.add(_Token(
          offset, offset + line.length, TextStyle(color: colors.hr)));
      return;
    }

    // Blockquote
    if (line.startsWith('> ')) {
      out.add(_Token(
          offset, offset + 2, TextStyle(color: colors.marker)));
      out.add(_Token(
        offset + 2,
        offset + line.length,
        TextStyle(color: colors.blockquote, fontStyle: FontStyle.italic),
      ));
      return;
    }

    // List marker
    final listMatch = RegExp(r'^(\s*(?:[-*+]|\d+\.)\s)').firstMatch(line);
    if (listMatch != null) {
      out.add(_Token(
        offset,
        offset + listMatch.end,
        TextStyle(color: colors.listMarker),
      ));
    }
  }

  void _collectInlineTokens(
      String text, List<_Token> out, WriterColors colors) {
    for (final (pattern, styleBuilder) in _inlineStylePatterns) {
      for (final m in pattern.allMatches(text)) {
        out.add(_Token(m.start, m.end, styleBuilder(colors)!));
      }
    }
  }

  List<InlineSpan> _buildSpans(
      String text, List<_Token> tokens, TextStyle base) {
    final spans = <InlineSpan>[];
    int pos = 0;
    for (final token in tokens) {
      if (token.start < pos) continue;
      if (token.start > pos) {
        spans.add(
            TextSpan(text: text.substring(pos, token.start), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(token.start, token.end),
        style: base.merge(token.style),
      ));
      pos = token.end;
    }
    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos), style: base));
    }
    return spans;
  }
}

class _Token {
  final int start;
  final int end;
  final TextStyle style;

  const _Token(this.start, this.end, this.style);
}
