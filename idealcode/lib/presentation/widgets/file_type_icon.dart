import 'package:flutter/material.dart';

import '../../data/models/project_file_model.dart';

class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({super.key, required this.fileType});

  final FileType fileType;

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (fileType) {
      case FileType.config:
        iconData = Icons.settings;
        iconColor = Colors.blue;
        break;
      case FileType.code:
        iconData = Icons.code;
        iconColor = Colors.green;
        break;
      case FileType.resource:
        iconData = Icons.image;
        iconColor = Colors.orange;
        break;
      case FileType.documentation:
        iconData = Icons.description;
        iconColor = Colors.purple;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 24,
    );
  }
}
