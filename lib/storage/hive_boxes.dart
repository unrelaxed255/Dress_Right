import 'package:hive_flutter/hive_flutter.dart';
import 'package:dress_right/models/member.dart';
import 'package:dress_right/models/inspection.dart';
import 'package:dress_right/models/inspection_item.dart';
import 'package:dress_right/models/prefs.dart';

class HiveBoxes {
  HiveBoxes._();

  static const members = 'members';
  static const inspections = 'inspections';
  static const inspectionItems = 'inspection_items';
  static const prefs = 'prefs';
  static const prefsKey = 'singleton';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MemberAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MemberAssignmentAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(InspectionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(InspectionItemAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PrefsAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(EmailSignatureAdapter());
    }

    await Future.wait([
      Hive.openBox<Member>(members),
      Hive.openBox<Inspection>(inspections),
      Hive.openBox<InspectionItem>(inspectionItems),
      Hive.openBox<Prefs>(prefs),
    ]);

    final prefsBox = Hive.box<Prefs>(prefs);
    if (prefsBox.isEmpty) {
      await prefsBox.put(prefsKey, Prefs());
    }

    _initialized = true;
  }

  static Box<Member> membersBox() => Hive.box<Member>(members);
  static Box<Inspection> inspectionsBox() => Hive.box<Inspection>(inspections);
  static Box<InspectionItem> inspectionItemsBox() => Hive.box<InspectionItem>(inspectionItems);
  static Box<Prefs> prefsBox() => Hive.box<Prefs>(prefs);

  static Prefs get prefsSnapshot => prefsBox().get(prefsKey, defaultValue: Prefs())!;

  static Future<void> savePrefs(Prefs prefs) async {
    await prefsBox().put(prefsKey, prefs);
  }
}
