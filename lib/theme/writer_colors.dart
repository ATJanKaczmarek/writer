import 'package:flutter/material.dart';

/// Semantic color tokens for the Writer app.
///
/// Use [WriterColors.of(context)] anywhere you have a [BuildContext].
/// The palette is chosen automatically based on [Theme.of(context).brightness].
class WriterColors {
  const WriterColors._({
    required this.appBg,
    required this.editorBg,
    required this.gutterBg,
    required this.surfaceHover,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.heading,
    required this.bold,
    required this.italic,
    required this.marker,
    required this.blockquote,
    required this.code,
    required this.codeBg,
    required this.link,
    required this.listMarker,
    required this.hr,
    required this.cursor,
    required this.lineNumber,
  });

  final Color appBg;        // toolbar, explorer, preview bg
  final Color editorBg;     // text-editor canvas
  final Color gutterBg;     // line-number gutter
  final Color surfaceHover; // selected note item bg
  final Color divider;      // borders, drag handles, separators

  // Text
  final Color textPrimary;   // body copy in editor
  final Color textSecondary; // tool labels, file names
  final Color textMuted;     // folder name, placeholders
  final Color textDisabled;  // empty-state icons, subtle labels

  // Markdown syntax tokens
  final Color heading;
  final Color bold;
  final Color italic;
  final Color marker;     // ##, **, *, >, etc.
  final Color blockquote;
  final Color code;
  final Color codeBg;
  final Color link;
  final Color listMarker;
  final Color hr;

  // Editor chrome
  final Color cursor;
  final Color lineNumber;

  // -------------------------------------------------------------------------
  // Palettes
  // -------------------------------------------------------------------------

  static const _dark = WriterColors._(
    appBg:        Color(0xFF18181b), // zinc-950
    editorBg:     Color(0xFF1c1c1e),
    gutterBg:     Color(0xFF18181b),
    surfaceHover: Color(0xFF27272a), // zinc-800
    divider:      Color(0xFF27272a),

    textPrimary:   Color(0xFFe4e4e7), // zinc-200
    textSecondary: Color(0xFFa1a1aa), // zinc-400
    textMuted:     Color(0xFF71717a), // zinc-500
    textDisabled:  Color(0xFF52525b), // zinc-600

    heading:    Color(0xFFfafafa),   // zinc-50
    bold:       Color(0xFFfafafa),
    italic:     Color(0xFFd4d4d8),  // zinc-300
    marker:     Color(0xFF52525b),
    blockquote: Color(0xFF71717a),
    code:       Color(0xFFf97316),  // orange-500
    codeBg:     Color(0xFF27272a),
    link:       Color(0xFF60a5fa),  // blue-400
    listMarker: Color(0xFF818cf8),  // indigo-400
    hr:         Color(0xFF3f3f46),  // zinc-700

    cursor:     Color(0xFF818cf8),
    lineNumber: Color(0xFF3f3f46),
  );

  static const _light = WriterColors._(
    appBg:        Color(0xFFfafafa), // zinc-50
    editorBg:     Color(0xFFffffff),
    gutterBg:     Color(0xFFF4F4F5), // zinc-100
    surfaceHover: Color(0xFFe4e4e7), // zinc-200
    divider:      Color(0xFFe4e4e7),

    textPrimary:   Color(0xFF18181b), // zinc-950
    textSecondary: Color(0xFF52525b), // zinc-600
    textMuted:     Color(0xFF71717a), // zinc-500
    textDisabled:  Color(0xFFa1a1aa), // zinc-400

    heading:    Color(0xFF09090b),   // zinc-950
    bold:       Color(0xFF09090b),
    italic:     Color(0xFF52525b),  // zinc-600
    marker:     Color(0xFFa1a1aa),  // zinc-400
    blockquote: Color(0xFF71717a),
    code:       Color(0xFFc2410c),  // orange-700
    codeBg:     Color(0xFFF4F4F5),
    link:       Color(0xFF2563eb),  // blue-600
    listMarker: Color(0xFF4f46e5),  // indigo-600
    hr:         Color(0xFFd4d4d8),  // zinc-300

    cursor:     Color(0xFF6366f1),  // indigo-500
    lineNumber: Color(0xFFa1a1aa),
  );

  // -------------------------------------------------------------------------
  // Public accessor
  // -------------------------------------------------------------------------

  static WriterColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }
}
