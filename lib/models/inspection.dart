import 'package:hive/hive.dart';

part 'inspection.g.dart';

@HiveType(typeId: 2)
class Inspection extends HiveObject {
  Inspection({
    required this.inspectionId,
    required this.uniformType,
    this.status = InspectionStatus.draft,
    DateTime? startedAt,
    this.completedAt,
    this.summary,
  }) : startedAt = startedAt ?? DateTime.now();

  @HiveField(0)
  final String inspectionId;

  @HiveField(1)
  final String uniformType;

  @HiveField(2)
  final String status;

  @HiveField(3)
  final DateTime startedAt;

  @HiveField(4)
  final DateTime? completedAt;

  @HiveField(5)
  final String? summary;

  Inspection copyWith({
    String? uniformType,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? summary,
  }) {
    return Inspection(
      inspectionId: inspectionId,
      uniformType: uniformType ?? this.uniformType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      summary: summary ?? this.summary,
    );
  }
}

class InspectionStatus {
  static const draft = 'draft';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
}
