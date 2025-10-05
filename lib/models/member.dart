import 'package:hive/hive.dart';

part 'member.g.dart';

@HiveType(typeId: 0)
class Member extends HiveObject {
  Member({
    required this.memberId,
    required this.rank,
    required this.name,
    required this.workcenter,
    this.status = MemberStatus.active,
    List<MemberAssignment>? assignments,
    DateTime? updatedAt,
  })  : assignments = assignments ?? <MemberAssignment>[],
        updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  final String memberId;

  @HiveField(1)
  final String rank;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String workcenter;

  @HiveField(4)
  final String status;

  @HiveField(5)
  final List<MemberAssignment> assignments;

  @HiveField(6)
  final DateTime updatedAt;

  Member copyWith({
    String? rank,
    String? name,
    String? workcenter,
    String? status,
    List<MemberAssignment>? assignments,
    DateTime? updatedAt,
  }) {
    return Member(
      memberId: memberId,
      rank: rank ?? this.rank,
      name: name ?? this.name,
      workcenter: workcenter ?? this.workcenter,
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class MemberStatus {
  static const active = 'active';
  static const departed = 'departed';
}

@HiveType(typeId: 1)
class MemberAssignment extends HiveObject {
  MemberAssignment({
    required this.workcenter,
    required this.startedAt,
    this.endedAt,
  });

  @HiveField(0)
  final String workcenter;

  @HiveField(1)
  final DateTime startedAt;

  @HiveField(2)
  final DateTime? endedAt;

  MemberAssignment copyWith({
    String? workcenter,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return MemberAssignment(
      workcenter: workcenter ?? this.workcenter,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
