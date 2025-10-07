import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

part 'project_file_model.freezed.dart';
part 'project_file_model.g.dart';

// Внешние функции для вычисляемых свойств
String _getDisplayName(ProjectFile file) => file.name ?? file.path.split('/').last;

String _getExtension(ProjectFile file) => file.path.split('.').last.toLowerCase();

bool _getIsEmpty(ProjectFile file) => file.content.trim().isEmpty;

bool _getIsConfig(ProjectFile file) => 
    FileExtensions.configFiles.contains('.${_getExtension(file)}');

bool _getIsCode(ProjectFile file) => 
    FileExtensions.codeFiles.contains('.${_getExtension(file)}');

bool _getIsResource(ProjectFile file) => 
    FileExtensions.resourceFiles.contains('.${_getExtension(file)}');

bool _getIsDocumentation(ProjectFile file) => 
    FileExtensions.docFiles.contains('.${_getExtension(file)}');

String _getFormattedSize(ProjectFile file) {
  final size = file.size;
  if (size == 0) return '0 B';
  if (size < 1024) return '${size} B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _getFormattedDate(ProjectFile file) => 
    DateFormat('MMM dd HH:mm').format(file.lastModified);

String _getDisplayPath(ProjectFile file) {
  final path = file.path;
  if (path.length > 30) {
    return '${path.substring(0, 15)}...${path.substring(path.length - 15)}';
  }
  return path;
}

FileType _getTypeFromPath(String path) {
  final extension = path.split('.').last.toLowerCase();
  
  if (FileExtensions.configFiles.contains('.$extension')) return FileType.config;
  if (FileExtensions.codeFiles.contains('.$extension')) return FileType.code;
  if (FileExtensions.resourceFiles.contains('.$extension')) return FileType.resource;
  if (FileExtensions.docFiles.contains('.$extension')) return FileType.documentation;
  
  return FileType.resource;
}

@freezed
class ProjectFile with _$ProjectFile {
  @HiveType(typeId: 1)
  const factory ProjectFile({
    @HiveField(0) 
    @JsonKey(name: 'id') 
    required String id,
    @HiveField(1) 
    @JsonKey(name: 'path') 
    required String path,
    @HiveField(2) 
    @JsonKey(name: 'name') 
    String? name,
    @HiveField(3) 
    @JsonKey(name: 'content', defaultValue: '') 
    @Default('') String content,
    @HiveField(4) 
    @JsonKey(name: 'type') 
    @Default(FileType.code) FileType type,
    @HiveField(5) 
    @JsonKey(name: 'status') 
    @Default(FileStatus.empty) FileStatus status,
    @HiveField(6) 
    @JsonKey(name: 'dependencies', defaultValue: <String>[]) 
    @Default([]) List<String> dependencies,
    @HiveField(7) 
    @JsonKey(name: 'x') 
    @Default(0.0) double x,
    @HiveField(8) 
    @JsonKey(name: 'y') 
    @Default(0.0) double y,
    @HiveField(9) 
    @JsonKey(name: 'lastModified') 
    required DateTime lastModified,
    @HiveField(10) 
    @JsonKey(name: 'isOpen', defaultValue: false) 
    @Default(false) bool isOpen,
    @HiveField(11) 
    @JsonKey(name: 'annotation', defaultValue: '') 
    @Default('') String annotation,
    @HiveField(12) 
    @JsonKey(name: 'size', defaultValue: 0) 
    @Default(0) int size,
  }) = _ProjectFile;

  factory ProjectFile.fromJson(Map<String, dynamic> json) => _$ProjectFileFromJson(json);
  
  // Factory constructors
  factory ProjectFile.empty(String path) {
    final id = '${DateTime.now().millisecondsSinceEpoch}_$path';
    return ProjectFile(
      id: id,
      path: path,
      name: path.split('/').last,
      lastModified: DateTime.now(),
      type: _getTypeFromPath(path),
      status: FileStatus.empty,
    );
  }
  
  factory ProjectFile.fromPath(String path, {String content = ''}) {
    final file = ProjectFile.empty(path);
    if (content.isNotEmpty) {
      return file.copyWith(
        content: content,
        status: content.trim().isEmpty ? FileStatus.empty : FileStatus.completed,
        lastModified: DateTime.now(),
        size: content.length,
      );
    }
    return file;
  }
}

// Extension для методов
extension ProjectFileExtension on ProjectFile {
  String get displayName => _getDisplayName(this);
  String get extension => _getExtension(this);
  bool get isEmpty => _getIsEmpty(this);
  bool get isConfig => _getIsConfig(this);
  bool get isCode => _getIsCode(this);
  bool get isResource => _getIsResource(this);
  bool get isDocumentation => _getIsDocumentation(this);
  String get formattedSize => _getFormattedSize(this);
  String get formattedDate => _getFormattedDate(this);
  String get displayPath => _getDisplayPath(this);
  
  ProjectFile updateContent(String newContent) {
    return copyWith(
      content: newContent,
      status: newContent.trim().isEmpty ? FileStatus.empty : FileStatus.editing,
      lastModified: DateTime.now(),
      size: newContent.length,
    );
  }
  
  ProjectFile updatePosition(double x, double y) {
    return copyWith(
      x: x.clamp(0.0, double.infinity),
      y: y.clamp(0.0, double.infinity),
      lastModified: DateTime.now(),
    );
  }
  
  ProjectFile updateStatus(FileStatus newStatus) {
    return copyWith(
      status: newStatus,
      lastModified: DateTime.now(),
    );
  }
  
  bool hasDependency(String dependencyId) {
    return dependencies.contains(dependencyId);
  }
}

@HiveType(typeId: 3)
enum FileStatus {
  @HiveField(0) empty('empty'),
  @HiveField(1) editing('editing'),
  @HiveField(2) completed('completed'),
  @HiveField(3) error('error'),
  @HiveField(4) loading('loading');

  const FileStatus(this.value);
  final String value;
  
  Color get color {
    switch (this) {
      case FileStatus.empty:
        return Colors.grey;
      case FileStatus.editing:
        return Colors.orange;
      case FileStatus.completed:
        return Colors.green;
      case FileStatus.error:
        return Colors.red;
      case FileStatus.loading:
        return Colors.blue;
    }
  }
  
  IconData get icon {
    switch (this) {
      case FileStatus.empty:
        return Icons.radio_button_unchecked;
      case FileStatus.editing:
        return Icons.edit;
      case FileStatus.completed:
        return Icons.check_circle;
      case FileStatus.error:
        return Icons.error;
      case FileStatus.loading:
        return Icons.hourglass_empty;
    }
  }
  
  factory FileStatus.fromString(String value) {
    return FileStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => FileStatus.empty,
    );
  }
}

@HiveType(typeId: 4)
enum FileType {
  @HiveField(0) config('config'),
  @HiveField(1) code('code'),
  @HiveField(2) resource('resource'),
  @HiveField(3) documentation('documentation');

  const FileType(this.value);
  final String value;
  
  Color get color {
    switch (this) {
      case FileType.config:
        return Colors.blue;
      case FileType.code:
        return Colors.green;
      case FileType.resource:
        return Colors.orange;
      case FileType.documentation:
        return Colors.purple;
    }
  }
  
  IconData get icon {
    switch (this) {
      case FileType.config:
        return Icons.settings;
      case FileType.code:
        return Icons.code;
      case FileType.resource:
        return Icons.image;
      case FileType.documentation:
        return Icons.description;
    }
  }
  
  factory FileType.fromString(String value) {
    return FileType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => FileType.code,
    );
  }
}