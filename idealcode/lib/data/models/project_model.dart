import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'project_file_model.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

@freezed
class Project with _$Project {
  @HiveType(typeId: 0)
  const factory Project({
    @HiveField(0) 
    @JsonKey(name: 'id') 
    required String id,
    @HiveField(1) 
    @JsonKey(name: 'title') 
    required String title,
    @HiveField(2) 
    @JsonKey(name: 'description', defaultValue: '') 
    @Default('') String description,
    @HiveField(3) 
    @JsonKey(name: 'files', defaultValue: <ProjectFile>[]) 
    @Default([]) List<ProjectFile> files,
    @HiveField(4) 
    @JsonKey(name: 'status') 
    @Default(ProjectStatus.draft) ProjectStatus status,
    @HiveField(5) 
    @JsonKey(name: 'createdAt') 
    required DateTime createdAt,
    @HiveField(6) 
    @JsonKey(name: 'updatedAt') 
    required DateTime updatedAt,
    @HiveField(7) 
    @JsonKey(name: 'version', defaultValue: '1.0.0') 
    @Default('1.0.0') String version,
    @HiveField(8) 
    @JsonKey(name: 'language', defaultValue: 'dart') 
    @Default('dart') String language,
    @HiveField(9) 
    @JsonKey(name: 'platform', defaultValue: 'mobile') 
    @Default('mobile') String platform,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  
  // Convenience methods
  String get displayDate => DateFormat('MMM dd, yyyy').format(updatedAt);
  
  String get filesCount => '${files.length} files';
  
  bool get hasFiles => files.isNotEmpty;
  
  bool get isEmpty => files.isEmpty && description.isEmpty;
  
  Project copyWithUpdatedFiles(List<ProjectFile> newFiles) {
    return copyWith(
      files: newFiles,
      updatedAt: DateTime.now(),
      status: ProjectStatus.inProgress,
    );
  }
  
  Project updateFile(String fileId, ProjectFile updatedFile) {
    final updatedFiles = files.map((file) {
      return file.id == fileId ? updatedFile : file;
    }).toList();
    
    return copyWithUpdatedFiles(updatedFiles);
  }
  
  ProjectFile? getFileById(String fileId) {
    try {
      return files.firstWhere((file) => file.id == fileId);
    } catch (e) {
      return null;
    }
  }
  
  String get formattedDescription {
    if (description.isEmpty) return 'No description';
    return description.length > 100 
        ? '${description.substring(0, 100)}...' 
        : description;
  }
}

@HiveType(typeId: 2)
class ProjectStatus extends HiveObject {
  @HiveField(0)
  final String value;
  
  const ProjectStatus(this.value);
  
  static const ProjectStatus draft = ProjectStatus('draft');
  static const ProjectStatus inProgress = ProjectStatus('inProgress');
  static const ProjectStatus completed = ProjectStatus('completed');
  static const ProjectStatus error = ProjectStatus('error');
  static const ProjectStatus archived = ProjectStatus('archived');
  
  factory ProjectStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return draft;
      case 'inprogress':
        return inProgress;
      case 'completed':
        return completed;
      case 'error':
        return error;
      case 'archived':
        return archived;
      default:
        return draft;
    }
  }
  
  @override
  String toString() => value;
  
  Color get color {
    switch (value) {
      case 'draft':
        return Colors.grey;
      case 'inProgress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'archived':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  IconData get icon {
    switch (value) {
      case 'draft':
        return Icons.draft;
      case 'inProgress':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }
}
