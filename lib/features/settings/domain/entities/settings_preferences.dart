import 'package:equatable/equatable.dart';

class SettingsPreferences extends Equatable {
  const SettingsPreferences({
    required this.pushEnabled,
    required this.localAiEnabled,
  });

  final bool pushEnabled;
  final bool localAiEnabled;

  SettingsPreferences copyWith({bool? pushEnabled, bool? localAiEnabled}) {
    return SettingsPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      localAiEnabled: localAiEnabled ?? this.localAiEnabled,
    );
  }

  @override
  List<Object?> get props => <Object?>[pushEnabled, localAiEnabled];
}
