import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'project_file_model.freezed.dart';
part 'project_file_model.g.dart';

@freezed
class ProjectFile with _$ProjectFile {
  @HiveType(typeId: 1)
  const factory ProjectFile({
    @HiveField(0) required String id,
    @HiveField(1) required String path,
    @HiveField(2) @Default('') String content,
    @HiveField(3) @Default(FileType.code) FileType type,
    @HiveField(4) @Default(FileStatus.empty) FileStatus status,
    @HiveField(5) @Default([]) List<String> dependencies,
    @HiveField(6) @Default(0.0) double x,
    @HiveField(7) @Default(0.0) double y,
    @HiveField(8) required DateTime lastModified,
  }) = _ProjectFile;

  factory ProjectFile.fromJson(Map<String, dynamic> json) =>
      _$ProjectFileFromJson(json);

  String get name => path.split('/').last;
}

@HiveType(typeId: 3)
enum FileStatus {
  @HiveField(0)
  empty,
  @HiveField(1)
  editing,
  @HiveField(2)
  completed,
  @HiveField(3)
  error,
}

@HiveType(typeId: 4)
enum FileType {
  @HiveField(0)
  config,
  @HiveField(1)
  code,
  @HiveField(2)
  resource,
  @HiveField(3)
  documentation,
}
