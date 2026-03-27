import '../../../../core/usecase/usecase.dart';
import '../entities/home_dashboard.dart';
import '../repositories/home_repository.dart';

class GetHomeDashboard implements UseCase<Future<HomeDashboard>, NoParams> {
  GetHomeDashboard(this._repository);

  final HomeRepository _repository;

  @override
  Future<HomeDashboard> call(NoParams params) {
    return _repository.getDashboard();
  }
}
