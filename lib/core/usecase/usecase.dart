abstract class UseCase<T, Params> {
  T call(Params params);
}

class NoParams {
  const NoParams();
}
