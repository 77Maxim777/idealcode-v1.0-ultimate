import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import 'project_file_model.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

@freezed
class Project with _$Project {
  @HiveType(typeId: 0)
  const factory Project({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) String? description,
    @HiveField(3) @Default([]) List<ProjectFile> files,
    @HiveField(4) @Default(ProjectStatus.draft) ProjectStatus status,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) required DateTime updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}

@HiveType(typeId: 2)
enum ProjectStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
  @HiveField(3)
  error,
}
