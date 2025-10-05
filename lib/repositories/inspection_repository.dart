import 'dart:convert';

import 'package:dress_right/models/inspection.dart';
import 'package:dress_right/models/inspection_item.dart';
import 'package:dress_right/storage/hive_boxes.dart';
import 'package:dress_right/utils/checklist_loader.dart';
import 'package:uuid/uuid.dart';

class InspectionRepository {
  InspectionRepository();

  final _uuid = const Uuid();

  List<Inspection> fetchInspections() {
    final inspections = HiveBoxes.inspectionsBox().values.toList();
    inspections.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return inspections;
  }

  List<InspectionItem> fetchItems(String inspectionId) {
    return HiveBoxes
        .inspectionItemsBox()
        .values
        .where((item) => item.inspectionId == inspectionId)
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  Future<Inspection> createInspection(String uniformType, ChecklistDefinition checklist) async {
    final inspectionId = _uuid.v4();
    final inspection = Inspection(
      inspectionId: inspectionId,
      uniformType: uniformType,
      status: InspectionStatus.inProgress,
    );

    final itemsBox = HiveBoxes.inspectionItemsBox();
    for (final item in checklist.items) {
      final inspectionItem = InspectionItem(
        compositeId: '$inspectionId:${item.id}',
        inspectionId: inspectionId,
        itemId: item.id,
        fieldKey: item.fieldKey,
        label: item.label,
      );
      await itemsBox.put(inspectionItem.compositeId, inspectionItem);
    }

    await HiveBoxes.inspectionsBox().put(inspectionId, inspection);
    return inspection;
  }

  Future<void> updateItem(InspectionItem item) async {
    await HiveBoxes.inspectionItemsBox().put(item.compositeId, item);
  }

  Future<void> setItemResult(InspectionItem item, String result, {String? comment}) async {
    final updated = item.copyWith(
      result: result,
      comment: comment ?? item.comment,
    );
    await updateItem(updated);
  }

  Future<void> setItemComment(InspectionItem item, String comment) async {
    final updated = item.copyWith(comment: comment);
    await updateItem(updated);
  }

  Future<void> completeInspection(String inspectionId) async {
    final items = fetchItems(inspectionId);
    final counts = <String, int>{
      InspectionResult.pass: 0,
      InspectionResult.fail: 0,
      InspectionResult.na: 0,
    };
    for (final item in items) {
      counts[item.result] = (counts[item.result] ?? 0) + 1;
    }

    final summary = jsonEncode(counts);
    final inspectionBox = HiveBoxes.inspectionsBox();
    final inspection = inspectionBox.get(inspectionId);
    if (inspection == null) {
      return;
    }

    final updated = inspection.copyWith(
      status: InspectionStatus.completed,
      completedAt: DateTime.now(),
      summary: summary,
    );
    await inspectionBox.put(inspectionId, updated);
  }

  Future<void> reopenInspection(String inspectionId) async {
    final inspectionBox = HiveBoxes.inspectionsBox();
    final inspection = inspectionBox.get(inspectionId);
    if (inspection == null) {
      return;
    }

    final reopened = Inspection(
      inspectionId: inspection.inspectionId,
      uniformType: inspection.uniformType,
      status: InspectionStatus.inProgress,
      startedAt: inspection.startedAt,
    );

    await inspectionBox.put(inspectionId, reopened);
  }
}

