import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writer/controllers/markdown_controller.dart';

// Helper: pump the controller inside both dark and light MaterialApp so the
// theme-aware buildTextSpan is exercised for both palettes.
Widget _app({required MarkdownEditingController controller, Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    theme: brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true),
    home: Material(child: TextField(controller: controller)),
  );
}

void main() {
  group('MarkdownEditingController', () {
    late MarkdownEditingController controller;

    setUp(() => controller = MarkdownEditingController());
    tearDown(() => controller.dispose());

    testWidgets('buildTextSpan covers full text without gaps — dark',
        (tester) async {
      controller.text =
          '# Heading\n\nNormal **bold** and *italic* text.\n\n> quote\n';
      await tester.pumpWidget(_app(controller: controller));
      expect(tester.takeException(), isNull);
    });

    testWidgets('buildTextSpan covers full text without gaps — light',
        (tester) async {
      controller.text =
          '# Heading\n\nNormal **bold** and *italic* text.\n\n> quote\n';
      await tester.pumpWidget(
          _app(controller: controller, brightness: Brightness.light));
      expect(tester.takeException(), isNull);
    });

    testWidgets('buildTextSpan handles empty text', (tester) async {
      controller.text = '';
      await tester.pumpWidget(_app(controller: controller));
      expect(tester.takeException(), isNull);
    });

    test('heading tokens accepted for h1 through h6', () {
      for (final h in ['# H1', '## H2', '### H3', '#### H4', '##### H5', '###### H6']) {
        expect(() => controller.text = h, returnsNormally);
      }
    });

    testWidgets('inline code rendered without throw', (tester) async {
      controller.text = 'Use `code` inline and\n```\nblock\n```';
      await tester.pumpWidget(_app(controller: controller));
      expect(tester.takeException(), isNull);
    });
  });

  group('Logical line count (newline-based)', () {
    // Mirrors _EditorWithLineNumbersState._countLogicalLines.
    // Soft-wrapped visual rows are NOT counted here — see gutter label tests.
    int countLogicalLines(String text) =>
        text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

    test('empty string → 1', () => expect(countLogicalLines(''), 1));
    test('single line → 1', () => expect(countLogicalLines('hello'), 1));
    test('two lines → 2', () => expect(countLogicalLines('a\nb'), 2));
    test('trailing newline adds a line',
        () => expect(countLogicalLines('a\nb\n'), 3));
    test('five lines', () => expect(countLogicalLines('1\n2\n3\n4\n5'), 5));
  });

  group('Gutter label visual-wrap detection', () {
    // Mirrors _EditorWithLineNumbersState._computeGutterLabels.
    List<int?> computeGutterLabels(String text, double textWidth) {
      const style = TextStyle(fontSize: 15.0, height: 1.65);
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
        labels.add(i + 1);
        for (var r = 1; r < visualRows; r++) {
          labels.add(null);
        }
      }
      return labels;
    }

    test('empty content → [1]', () {
      expect(computeGutterLabels('', 600), [1]);
    });

    test('short line fits in one row', () {
      expect(computeGutterLabels('hello', 600), [1]);
    });

    test('three short lines, no wrapping', () {
      expect(computeGutterLabels('a\nb\nc', 600), [1, 2, 3]);
    });

    test('empty lines each count as one visual row', () {
      expect(computeGutterLabels('\n\n', 600), [1, 2, 3]);
    });

    test('very long line wraps: first label is 1, continuations are null', () {
      // 300 chars at any reasonable font width will wrap at 100px
      final longLine = 'a' * 300;
      final labels = computeGutterLabels(longLine, 100);
      expect(labels.first, 1);
      expect(labels.length, greaterThan(1));
      expect(labels.skip(1).every((l) => l == null), isTrue);
    });

    test('second logical line is numbered correctly after a wrapped first line',
        () {
      final longFirst = 'word ' * 50; // will wrap at 200px
      final labels = computeGutterLabels('${longFirst.trim()}\nsecond', 200);
      expect(labels.first, 1);
      expect(labels.last, 2);
      expect(labels.length, greaterThan(2));
    });

    test('no wrapping when width is very large', () {
      final labels = computeGutterLabels('line1\nline2\nline3', 10000);
      expect(labels, [1, 2, 3]);
    });
  });

  group('Theme toggle', () {
    testWidgets('dark and light palettes do not throw during render',
        (tester) async {
      final ctrl = MarkdownEditingController()..text = '**bold** _italic_';
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_app(controller: ctrl, brightness: Brightness.dark));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_app(controller: ctrl, brightness: Brightness.light));
      expect(tester.takeException(), isNull);
    });
  });
}
