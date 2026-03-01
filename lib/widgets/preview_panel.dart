import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../bloc/app_bloc.dart';
import '../theme/writer_colors.dart';
import '../utils/toc_generator.dart';

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final content =
        context.select<AppBloc, String>((b) => b.state.content);
    final isAcademicMode =
        context.select<AppBloc, bool>((b) => b.state.isAcademicMode);
    final c = WriterColors.of(context);

    final displayContent =
        isAcademicMode ? generateToc(content) + content : content;

    return Container(
      color: c.appBg,
      child: Markdown(
        data: displayContent,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        styleSheet: _buildStyleSheet(c),
        selectable: true,
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(WriterColors c) {
    final base = TextStyle(
      fontSize: 15,
      height: 1.65,
      color: c.textPrimary,
    );
    const codeFont = TextStyle(fontFamily: 'FiraCode');
    return MarkdownStyleSheet(
      p: base,
      h1: base.copyWith(
          fontSize: 28, fontWeight: FontWeight.bold, color: c.heading),
      h2: base.copyWith(
          fontSize: 24, fontWeight: FontWeight.bold, color: c.heading),
      h3: base.copyWith(
          fontSize: 20, fontWeight: FontWeight.bold, color: c.heading),
      h4: base.copyWith(
          fontSize: 18, fontWeight: FontWeight.bold, color: c.heading),
      h5: base.copyWith(
          fontSize: 16, fontWeight: FontWeight.bold, color: c.heading),
      h6: base.copyWith(
          fontSize: 14, fontWeight: FontWeight.bold, color: c.heading),
      strong: base.copyWith(fontWeight: FontWeight.bold, color: c.bold),
      em: base.copyWith(fontStyle: FontStyle.italic, color: c.italic),
      code: codeFont.merge(base.copyWith(
        color: c.code,
        backgroundColor: c.codeBg,
        fontSize: 13,
      )),
      codeblockDecoration: BoxDecoration(
        color: c.codeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      codeblockPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.textDisabled, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16),
      blockquote: base.copyWith(
          color: c.blockquote, fontStyle: FontStyle.italic),
      a: base.copyWith(
        color: c.link,
        decoration: TextDecoration.underline,
        decorationColor: c.link,
      ),
      listBullet: base.copyWith(color: c.listMarker),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.hr, width: 1)),
      ),
    );
  }
}
