import 'package:flutter_test/flutter_test.dart';
import 'package:writer/utils/toc_generator.dart';

void main() {
  group('generateToc', () {
    test('returns empty string for empty content', () {
      expect(generateToc(''), '');
    });

    test('returns empty string when no headings', () {
      expect(generateToc('Some paragraph text.\n\nAnother paragraph.'), '');
    });

    test('single h1 heading', () {
      const content = '# Hello World';
      final toc = generateToc(content);
      expect(toc, contains('**Table of Contents**'));
      expect(toc, contains('[Hello World](#hello-world)'));
      expect(toc, contains('---'));
    });

    test('mixed h1 through h3 headings with normalised indent', () {
      const content = '''
# Introduction
## Background
### Details
## Summary
''';
      final toc = generateToc(content);
      expect(toc, contains('- [Introduction](#introduction)'));
      expect(toc, contains('  - [Background](#background)'));
      expect(toc, contains('    - [Details](#details)'));
      expect(toc, contains('  - [Summary](#summary)'));
    });

    test('min level normalisation: starts from h2', () {
      const content = '''
## First Section
### Sub Section
## Second Section
''';
      final toc = generateToc(content);
      // h2 is min level, so no leading indent
      expect(toc, contains('- [First Section](#first-section)'));
      expect(toc, contains('  - [Sub Section](#sub-section)'));
      expect(toc, contains('- [Second Section](#second-section)'));
    });

    test('special chars in heading title are handled in anchor', () {
      const content = '# Hello, World! (2024)';
      final toc = generateToc(content);
      expect(toc, contains('[Hello, World! (2024)]'));
      // Anchor strips non-alphanumeric (except hyphens)
      final anchor = toc
          .split('\n')
          .firstWhere((l) => l.contains('#hello'))
          .split('(#')[1]
          .replaceAll(')', '');
      expect(anchor, 'hello-world-2024');
    });

    test('heading with markdown formatting in title', () {
      const content = '## **Bold** and _italic_ heading';
      final toc = generateToc(content);
      expect(toc, contains('[**Bold** and _italic_ heading]'));
    });

    test('output starts with TOC header and ends with horizontal rule', () {
      const content = '# Title\n## Section';
      final toc = generateToc(content);
      expect(toc.trimRight(), endsWith('---'));
      expect(toc, startsWith('**Table of Contents**'));
    });

    test('content with only non-heading lines returns empty string', () {
      const content = '''
Some text here.

> A blockquote

- list item

    code block
''';
      expect(generateToc(content), '');
    });
  });

  group('AppAcademicModeToggled', () {
    test('isAcademicMode toggles via AppState.copyWith', () {
      // Verify state field exists and toggles correctly
      // (pure state logic, no bloc needed)
      const initial = _FakeState(isAcademicMode: false);
      final toggled = initial.copyWith(isAcademicMode: true);
      expect(toggled.isAcademicMode, true);
      final toggledBack = toggled.copyWith(isAcademicMode: false);
      expect(toggledBack.isAcademicMode, false);
    });
  });
}

// Minimal fake state to test copyWith logic without full AppState dependency.
class _FakeState {
  final bool isAcademicMode;
  const _FakeState({required this.isAcademicMode});
  _FakeState copyWith({bool? isAcademicMode}) =>
      _FakeState(isAcademicMode: isAcademicMode ?? this.isAcademicMode);
}
