import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';

part 'project_file_model.freezed.dart';
part 'project_file_model.g.dart';

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
  
  // Computed properties
  String get displayName => name ?? path.split('/').last;
  
  String get extension => path.split('.').last.toLowerCase();
  
  bool get isEmpty => content.trim().isEmpty;
  
  bool get isConfig => FileExtensions.configFiles.contains('.$extension');
  
  bool get isCode => FileExtensions.codeFiles.contains('.$extension');
  
  bool get isResource => FileExtensions.resourceFiles.contains('.$extension');
  
  bool get isDocumentation => FileExtensions.docFiles.contains('.$extension');
  
  String get formattedSize {
    if (size == 0) return '0 B';
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  String get formattedDate => DateFormat('MMM dd HH:mm').format(lastModified);
  
  String get displayPath {
    if (path.length > 30) {
      return '${path.substring(0, 15)}...${path.substring(path.length - 15)}';
    }
    return path;
  }
  
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
  
  // Methods
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
  
  static FileType _getTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    
    if (FileExtensions.configFiles.contains('.$extension')) return FileType.config;
    if (FileExtensions.codeFiles.contains('.$extension')) return FileType.code;
    if (FileExtensions.resourceFiles.contains('.$extension')) return FileType.resource;
    if (FileExtensions.docFiles.contains('.$extension')) return FileType.documentation;
    
    return FileType.resource;
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
    return switch (this) {
      FileStatus.empty => Colors.grey,
      FileStatus.editing => Colors.orange,
      FileStatus.completed => Colors.green,
      FileStatus.error => Colors.red,
      FileStatus.loading => Colors.blue,
    };
  }
  
  IconData get icon {
    return switch (this) {
      FileStatus.empty => Icons.radio_button_unchecked,
      FileStatus.editing => Icons.edit,
      FileStatus.completed => Icons.check_circle,
      FileStatus.error => Icons.error,
      FileStatus.loading => Icons.hourglass_empty,
    };
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
    return switch (this) {
      FileType.config => Colors.blue,
      FileType.code => Colors.green,
      FileType.resource => Colors.orange,
      FileType.documentation => Colors.purple,
    };
  }
  
  IconData get icon {
    return switch (this) {
      FileType.config => Icons.settings,
      FileType.code => Icons.code,
      FileType.resource => Icons.image,
      FileType.documentation => Icons.description,
    };
  }
  
  factory FileType.fromString(String value) {
    return FileType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => FileType.code,
    );
  }
}
