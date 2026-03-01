import 'dart:io';

class Note {
  final File file;
  final DateTime lastModified;

  Note({required this.file, required this.lastModified});

  String get name {
    final base = file.uri.pathSegments.last;
    return base.endsWith('.md') ? base.substring(0, base.length - 3) : base;
  }

  String get path => file.path;
}
