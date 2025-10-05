import 'dart:async';

import 'package:dress_right/models/inspection.dart';
import 'package:dress_right/models/inspection_item.dart';
import 'package:dress_right/repositories/inspection_repository.dart';
import 'package:dress_right/storage/hive_boxes.dart';
import 'package:dress_right/utils/checklist_loader.dart';
import 'package:flutter/foundation.dart';

class InspectionProvider extends ChangeNotifier {
  InspectionProvider(this._repository) {
    _load();
    _subscription = HiveBoxes.inspectionsBox().watch().listen((_) => _load());
  }

  final InspectionRepository _repository;
  late final StreamSubscription _subscription;
  List<Inspection> _inspections = [];

  List<Inspection> get inspections => _inspections;

  Future<List<ChecklistDefinition>> loadChecklists() => ChecklistLoader.loadAll();

  List<InspectionItem> itemsFor(String inspectionId) => _repository.fetchItems(inspectionId);

  Future<Inspection> createInspection(String uniformType, ChecklistDefinition checklist) async {
    final inspection = await _repository.createInspection(uniformType, checklist);
    _load();
    return inspection;
  }

  Future<void> recordResult(InspectionItem item, String result, {String? comment}) async {
    await _repository.setItemResult(item, result, comment: comment);
    notifyListeners();
  }

  Future<void> saveComment(InspectionItem item, String comment) async {
    await _repository.setItemComment(item, comment);
    notifyListeners();
  }

  Future<String?> validateCompletion(String inspectionId) async {
    final items = itemsFor(inspectionId);
    for (final item in items) {
      if (item.result == InspectionResult.fail) {
        if (item.comment == null || item.comment!.trim().isEmpty) {
          return item.label;
        }
      }
    }
    return null;
  }

  Future<void> completeInspection(String inspectionId) async {
    final blockingItem = await validateCompletion(inspectionId);
    if (blockingItem != null) {
      throw FormatException('Add comment for "$blockingItem" before completing.');
    }
    await _repository.completeInspection(inspectionId);
    _load();
  }

  Future<void> reopenInspection(String inspectionId) async {
    await _repository.reopenInspection(inspectionId);
    _load();
  }

  void _load() {
    _inspections = _repository.fetchInspections();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
