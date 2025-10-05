import 'package:hive/hive.dart';

part 'inspection_item.g.dart';

@HiveType(typeId: 3)
class InspectionItem extends HiveObject {
  InspectionItem({
    required this.compositeId,
    required this.inspectionId,
    required this.itemId,
    required this.fieldKey,
    required this.label,
    this.result = InspectionResult.na,
    this.comment,
  });

  @HiveField(0)
  final String compositeId;

  @HiveField(1)
  final String inspectionId;

  @HiveField(2)
  final String itemId;

  @HiveField(3)
  final String fieldKey;

  @HiveField(4)
  final String label;

  @HiveField(5)
  final String result;

  @HiveField(6)
  final String? comment;

  InspectionItem copyWith({
    String? result,
    String? comment,
  }) {
    return InspectionItem(
      compositeId: compositeId,
      inspectionId: inspectionId,
      itemId: itemId,
      fieldKey: fieldKey,
      label: label,
      result: result ?? this.result,
      comment: comment ?? this.comment,
    );
  }
}

class InspectionResult {
  static const pass = 'pass';
  static const fail = 'fail';
  static const na = 'na';
}
