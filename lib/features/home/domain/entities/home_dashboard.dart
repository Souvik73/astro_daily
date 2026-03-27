import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user.dart';
import 'home_feature_usage.dart';

class HomeDashboard extends Equatable {
  const HomeDashboard({required this.user, required this.featureUsage});

  final User user;
  final List<HomeFeatureUsage> featureUsage;

  @override
  List<Object?> get props => <Object?>[user, featureUsage];
}
