import 'package:dress_right/models/member.dart';
import 'package:dress_right/utils/roster_models.dart';
import 'package:dress_right/storage/hive_boxes.dart';
import 'package:uuid/uuid.dart';

class MemberRepository {
  MemberRepository();

  final _uuid = const Uuid();

  List<Member> fetchMembers() {
    final box = HiveBoxes.membersBox();
    final members = box.values.toList();
    members.sort((a, b) => a.name.compareTo(b.name));
    return members;
  }

  Future<void> importRoster(List<RosterRecord> records) async {
    final box = HiveBoxes.membersBox();
    final existingByKey = <String, Member>{
      for (final member in box.values)
        rosterNameKey(member.name): member,
    };

    for (final record in records) {
      final key = rosterNameKey(record.name);
      final existing = existingByKey[key];
      if (existing != null) {
        final assignments = List<MemberAssignment>.from(existing.assignments);
        if (existing.workcenter != record.workcenter) {
          if (assignments.isNotEmpty) {
            final latest = assignments.last;
            assignments[assignments.length - 1] = latest.copyWith(endedAt: DateTime.now());
          }
          assignments.add(
            MemberAssignment(workcenter: record.workcenter, startedAt: DateTime.now()),
          );
        }
        final updated = existing.copyWith(
          rank: record.rank,
          name: record.name,
          workcenter: record.workcenter,
          status: MemberStatus.active,
          assignments: assignments,
        );
        await box.put(existing.memberId, updated);
        existingByKey[key] = updated;
      } else {
        final memberId = _uuid.v4();
        final member = Member(
          memberId: memberId,
          rank: record.rank,
          name: record.name,
          workcenter: record.workcenter,
          assignments: [
            MemberAssignment(workcenter: record.workcenter, startedAt: DateTime.now()),
          ],
        );
        await box.put(memberId, member);
        existingByKey[key] = member;
      }
    }
  }

  Future<void> updateMember(Member member) async {
    await HiveBoxes.membersBox().put(member.memberId, member);
  }

  Future<void> markDeparted(Member member) async {
    final assignments = List<MemberAssignment>.from(member.assignments);
    if (assignments.isNotEmpty) {
      final last = assignments.last;
      assignments[assignments.length - 1] = last.copyWith(endedAt: DateTime.now());
    }
    final updated = member.copyWith(
      status: MemberStatus.departed,
      assignments: assignments,
    );
    await updateMember(updated);
  }

  Future<void> changeWorkcenter(Member member, String newWorkcenter) async {
    final assignments = List<MemberAssignment>.from(member.assignments);
    if (assignments.isNotEmpty) {
      final last = assignments.last;
      if (last.workcenter != newWorkcenter) {
        assignments[assignments.length - 1] = last.copyWith(endedAt: DateTime.now());
        assignments.add(
          MemberAssignment(workcenter: newWorkcenter, startedAt: DateTime.now()),
        );
      }
    } else {
      assignments.add(
        MemberAssignment(workcenter: newWorkcenter, startedAt: DateTime.now()),
      );
    }

    final updated = member.copyWith(
      workcenter: newWorkcenter,
      assignments: assignments,
      status: MemberStatus.active,
    );
    await updateMember(updated);
  }
}
