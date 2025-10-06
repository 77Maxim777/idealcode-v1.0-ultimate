import 'package:hive/hive.dart';

import '../models/project_model.dart';
import '../models/project_file_model.dart';

/// Register all Hive adapters
void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProjectAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ProjectFileAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ProjectStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(FileStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(FileTypeAdapter());
  }
}

/// Project Hive Adapter
class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Project(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      files: (fields[3] as List?)?.cast<ProjectFile>() ?? [],
      status: ProjectStatus.fromString(fields[4] as String? ?? 'draft'),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      version: fields[7] as String? ?? '1.0.0',
      language: fields[8] as String? ?? 'dart',
      platform: fields[9] as String? ?? 'mobile',
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.files)
      ..writeByte(4)
      ..write(obj.status.value)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.version)
      ..writeByte(8)
      ..write(obj.language)
      ..writeByte(9)
      ..write(obj.platform);
  }
}

/// ProjectFile Hive Adapter
class ProjectFileAdapter extends TypeAdapter<ProjectFile> {
  @override
  final int typeId = 1;

  @override
  ProjectFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return ProjectFile(
      id: fields[0] as String,
      path: fields[1] as String,
      name: fields[2] as String?,
      content: fields[3] as String? ?? '',
      type: FileType.fromString(fields[4] as String? ?? 'code'),
      status: FileStatus.fromString(fields[5] as String? ?? 'empty'),
      dependencies: (fields[6] as List?)?.cast<String>() ?? [],
      x: (fields[7] as double?)?.clamp(0.0, double.infinity) ?? 0.0,
      y: (fields[8] as double?)?.clamp(0.0, double.infinity) ?? 0.0,
      lastModified: fields[9] as DateTime,
      isOpen: fields[10] as bool? ?? false,
      annotation: fields[11] as String? ?? '',
      size: (fields[12] as int?)?.clamp(0, 10000000) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectFile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.type.value)
      ..writeByte(5)
      ..write(obj.status.value)
      ..writeByte(6)
      ..write(obj.dependencies)
      ..writeByte(7)
      ..write(obj.x)
      ..writeByte(8)
      ..write(obj.y)
      ..writeByte(9)
      ..write(obj.lastModified)
      ..writeByte(10)
      ..write(obj.isOpen)
      ..writeByte(11)
      ..write(obj.annotation)
      ..writeByte(12)
      ..write(obj.size);
  }
}

/// ProjectStatus Hive Adapter
class ProjectStatusAdapter extends TypeAdapter<ProjectStatus> {
  @override
  final int typeId = 2;

  @override
  ProjectStatus read(BinaryReader reader) {
    final value = reader.read() as String;
    return ProjectStatus.fromString(value);
  }

  @override
  void write(BinaryWriter writer, ProjectStatus obj) {
    writer.write(obj.value);
  }
}

/// FileStatus Hive Adapter
class FileStatusAdapter extends TypeAdapter<FileStatus> {
  @override
  final int typeId = 3;

  @override
  FileStatus read(BinaryReader reader) {
    final value = reader.read() as String;
    return FileStatus.fromString(value);
  }

  @override
  void write(BinaryWriter writer, FileStatus obj) {
    writer.write(obj.value);
  }
}

/// FileType Hive Adapter
class FileTypeAdapter extends TypeAdapter<FileType> {
  @override
  final int typeId = 4;

  @override
  FileType read(BinaryReader reader) {
    final value = reader.read() as String;
    return FileType.fromString(value);
  }

  @override
  void write(BinaryWriter writer, FileType obj) {
    writer.write(obj.value);
  }
}
