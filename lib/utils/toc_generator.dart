/// Generates a markdown Table of Contents string from [content].
///
/// Returns an empty string if no headings are found.
/// The TOC is formatted as:
/// ```
/// **Table of Contents**
///
/// - [Title](#anchor)
///   - [Sub-title](#sub-title)
///
/// ---
///
/// ```
String generateToc(String content) {
  final headingPattern = RegExp(r'^(#{1,6})\s+(.+?)$', multiLine: true);
  final matches = headingPattern.allMatches(content).toList();

  if (matches.isEmpty) return '';

  final levels = matches.map((m) => m.group(1)!.length).toList();
  final minLevel = levels.reduce((a, b) => a < b ? a : b);

  final buffer = StringBuffer();
  buffer.writeln('**Table of Contents**');
  buffer.writeln();

  for (final match in matches) {
    final level = match.group(1)!.length;
    final title = match.group(2)!.trim();
    final indent = '  ' * (level - minLevel);
    final anchor = _anchor(title);
    buffer.writeln('$indent- [$title](#$anchor)');
  }

  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln();

  return buffer.toString();
}

/// Converts a heading title to a GitHub-style anchor slug.
String _anchor(String title) {
  return title
      .toLowerCase()
      // Remove markdown formatting characters
      .replaceAll(RegExp(r'[*_`\[\]()#]'), '')
      // Replace spaces with hyphens
      .replaceAll(RegExp(r'\s+'), '-')
      // Remove remaining non-alphanumeric characters except hyphens
      .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
      // Collapse multiple hyphens
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
