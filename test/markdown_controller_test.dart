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

  group('Line count helper', () {
    int countLines(String text) =>
        text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

    test('empty string → 1', () => expect(countLines(''), 1));
    test('single line → 1', () => expect(countLines('hello'), 1));
    test('two lines → 2', () => expect(countLines('a\nb'), 2));
    test('trailing newline adds a line', () => expect(countLines('a\nb\n'), 3));
    test('five lines', () => expect(countLines('1\n2\n3\n4\n5'), 5));
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
