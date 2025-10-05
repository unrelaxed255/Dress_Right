import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dress_right/models/member.dart';
import 'package:dress_right/repositories/member_repository.dart';
import 'package:dress_right/storage/hive_boxes.dart';
import 'package:dress_right/utils/roster_models.dart';

class MemberProvider extends ChangeNotifier {
  MemberProvider(this._repository) {
    _load();
    _subscription = HiveBoxes.membersBox().watch().listen((_) => _load());
  }

  final MemberRepository _repository;
  late StreamSubscription _subscription;

  List<Member> _members = [];
  String? _workcenterFilter;
  String _statusFilter = 'all';

  List<Member> get members => _filteredMembers();
  List<Member> get allMembers => _members;
  String? get workcenterFilter => _workcenterFilter;
  String get statusFilter => _statusFilter;
  bool get hasMembers => _members.isNotEmpty;

  List<String> get availableWorkcenters {
    final set = <String>{};
    for (final member in _members) {
      if (member.workcenter.isNotEmpty) {
        set.add(member.workcenter);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> importRoster(List<RosterRecord> records) async {
    await _repository.importRoster(records);
    _load();
  }

  Future<void> markDeparted(Member member) async {
    await _repository.markDeparted(member);
    _load();
  }

  Future<void> changeWorkcenter(Member member, String newWorkcenter) async {
    await _repository.changeWorkcenter(member, newWorkcenter);
    _load();
  }

  void setWorkcenterFilter(String? filter) {
    _workcenterFilter = filter?.isEmpty == true ? null : filter;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  List<Member> _filteredMembers() {
    return _members.where((member) {
      final matchesWorkcenter = _workcenterFilter == null
          ? true
          : member.workcenter.toLowerCase() == _workcenterFilter!.toLowerCase();
      final matchesStatus = _statusFilter == 'all' ? true : member.status == _statusFilter;
      return matchesWorkcenter && matchesStatus;
    }).toList();
  }

  void _load() {
    _members = _repository.fetchMembers();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
