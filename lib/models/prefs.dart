import 'package:hive/hive.dart';

part 'prefs.g.dart';

@HiveType(typeId: 4)
class Prefs extends HiveObject {
  Prefs({
    this.theme = AppThemeMode.dark,
    EmailSignature? emailSignature,
    this.dafiLocalPath,
    this.dafiLastPage,
  }) : emailSignature = emailSignature ?? EmailSignature.empty();

  @HiveField(0)
  final String theme;

  @HiveField(1)
  final EmailSignature emailSignature;

  @HiveField(2)
  final String? dafiLocalPath;

  @HiveField(3)
  final int? dafiLastPage;

  Prefs copyWith({
    String? theme,
    EmailSignature? emailSignature,
    String? dafiLocalPath,
    int? dafiLastPage,
  }) {
    return Prefs(
      theme: theme ?? this.theme,
      emailSignature: emailSignature ?? this.emailSignature,
      dafiLocalPath: dafiLocalPath ?? this.dafiLocalPath,
      dafiLastPage: dafiLastPage ?? this.dafiLastPage,
    );
  }
}

class AppThemeMode {
  static const light = 'light';
  static const dark = 'dark';
  static const system = 'system';
}

@HiveType(typeId: 5)
class EmailSignature extends HiveObject {
  EmailSignature({
    required this.rankName,
    required this.phone,
    required this.email,
  });

  factory EmailSignature.empty() => EmailSignature(
        rankName: '',
        phone: '',
        email: '',
      );

  @HiveField(0)
  final String rankName;

  @HiveField(1)
  final String phone;

  @HiveField(2)
  final String email;

  EmailSignature copyWith({
    String? rankName,
    String? phone,
    String? email,
  }) {
    return EmailSignature(
      rankName: rankName ?? this.rankName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
