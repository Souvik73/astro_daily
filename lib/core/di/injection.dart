import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_router.dart';
import '../config/auth_environment.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/bloc/login_form_cubit.dart';
import '../../features/auth/bloc/profile_completion_cubit.dart';
import '../../features/auth/bloc/signup_form_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart'
    as auth_contract;
import '../../features/auth/domain/usecases/complete_profile.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/observe_auth_state.dart';
import '../../features/auth/domain/usecases/sign_in_with_apple.dart';
import '../../features/auth/domain/usecases/sign_in_with_email.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_up_with_email.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/update_subscription_tier.dart';
import '../../features/daily_horoscope/data/datasources/daily_horoscope_remote_data_source.dart';
import '../../features/daily_horoscope/data/repositories/daily_horoscope_repository_impl.dart';
import '../../features/daily_horoscope/domain/repositories/daily_horoscope_repository.dart';
import '../../features/daily_horoscope/domain/usecases/get_personalized_daily_horoscope.dart';
import '../../features/daily_horoscope/presentation/bloc/daily_horoscope_bloc.dart';
import '../../features/horoscope_chat/data/datasources/horoscope_chat_data_source.dart';
import '../../features/horoscope_chat/data/repositories/horoscope_chat_repository_impl.dart';
import '../../features/horoscope_chat/domain/repositories/horoscope_chat_repository.dart';
import '../../features/horoscope_chat/domain/usecases/send_horoscope_message.dart';
import '../../features/horoscope_chat/presentation/bloc/horoscope_chat_bloc.dart';
import '../../features/gemstones/data/datasources/gemstones_remote_data_source.dart';
import '../../features/gemstones/data/repositories/gemstones_repository_impl.dart';
import '../../features/gemstones/domain/repositories/gemstones_repository.dart';
import '../../features/gemstones/domain/usecases/get_gemstone_insight.dart';
import '../../features/gemstones/presentation/cubit/gemstones_cubit.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_dashboard.dart';
import '../../features/home/domain/usecases/grant_feature_reward.dart';
import '../../features/home/domain/usecases/request_feature_access.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/kundli/data/datasources/kundli_remote_data_source.dart';
import '../../features/kundli/data/repositories/kundli_repository_impl.dart';
import '../../features/kundli/domain/repositories/kundli_repository.dart';
import '../../features/kundli/domain/usecases/get_kundli_insight.dart';
import '../../features/kundli/presentation/cubit/kundli_cubit.dart';
import '../../features/matching/data/datasources/matching_remote_data_source.dart';
import '../../features/matching/data/repositories/matching_repository_impl.dart';
import '../../features/matching/domain/repositories/matching_repository.dart';
import '../../features/matching/domain/usecases/get_matching_result.dart';
import '../../features/matching/presentation/cubit/matching_cubit.dart';
import '../../features/numerology/data/datasources/numerology_remote_data_source.dart';
import '../../features/numerology/data/repositories/numerology_repository_impl.dart';
import '../../features/numerology/domain/repositories/numerology_repository.dart';
import '../../features/numerology/domain/usecases/get_numerology_insight.dart';
import '../../features/numerology/presentation/cubit/numerology_cubit.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/delete_account.dart';
import '../../features/settings/domain/usecases/get_settings_preferences.dart';
import '../../features/settings/domain/usecases/update_local_ai_enabled.dart';
import '../../features/settings/domain/usecases/update_push_enabled.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/subscription/data/datasources/subscription_remote_data_source.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/get_subscription_overview.dart';
import '../../features/subscription/domain/usecases/purchase_subscription_plan.dart';
import '../../features/subscription/domain/usecases/restore_subscription_purchases.dart';
import '../../features/subscription/presentation/cubit/subscription_cubit.dart';
import '../models/subscription_models.dart';
import '../policy/usage_policy.dart';
import '../services/contracts.dart';
import '../services/mock_services.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies({bool reset = false}) async {
  if (reset) {
    await sl.reset();
  }
  if (sl.isRegistered<AppRouter>()) {
    return;
  }

  sl.registerLazySingleton<AstroProvider>(() => MockAstroProvider());
  sl.registerLazySingleton<GemstoneEngine>(() => RuleBasedGemstoneEngine());
  sl.registerLazySingleton<AiPersonalizer>(() => LocalTemplateAiPersonalizer());
  sl.registerLazySingleton<BillingGateway>(() => MockBillingGateway());
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => SupabaseAuthLocalDataSource(
      supabaseClient: sl<SupabaseClient>(),
      googleSignIn: sl<GoogleSignIn>(),
      googleServerClientId: AuthEnvironment.googleServerClientId,
      googleIosClientId: AuthEnvironment.googleIosClientId,
      appleWebClientId: AuthEnvironment.appleWebClientId,
      appleWebRedirectUrl: AuthEnvironment.appleWebRedirectUrl,
      supabaseProfileTablesEnabled:
          AuthEnvironment.supabaseProfileTablesEnabled,
    ),
    dispose: (AuthLocalDataSource source) => source.dispose(),
  );
  sl.registerLazySingleton<auth_contract.AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl<AuthLocalDataSource>()),
  );

  sl.registerLazySingleton<ObserveAuthState>(
    () => ObserveAuthState(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<SignInWithEmail>(
    () => SignInWithEmail(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<SignUpWithEmail>(
    () => SignUpWithEmail(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<SignInWithGoogle>(
    () => SignInWithGoogle(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<SignInWithApple>(
    () => SignInWithApple(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<SignOut>(
    () => SignOut(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<CompleteProfile>(
    () => CompleteProfile(sl<auth_contract.AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateSubscriptionTier>(
    () => UpdateSubscriptionTier(sl<auth_contract.AuthRepository>()),
  );

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      observeAuthState: sl<ObserveAuthState>(),
      getCurrentUser: sl<GetCurrentUser>(),
      signOut: sl<SignOut>(),
      updateSubscriptionTier: sl<UpdateSubscriptionTier>(),
    ),
    dispose: (AuthBloc bloc) => bloc.close(),
  );

  sl.registerFactory<LoginFormCubit>(
    () => LoginFormCubit(
      signInWithEmail: sl<SignInWithEmail>(),
      signInWithGoogle: sl<SignInWithGoogle>(),
      signInWithApple: sl<SignInWithApple>(),
    ),
  );
  sl.registerFactory<SignupFormCubit>(
    () => SignupFormCubit(
      signUpWithEmail: sl<SignUpWithEmail>(),
      signInWithGoogle: sl<SignInWithGoogle>(),
      signInWithApple: sl<SignInWithApple>(),
    ),
  );
  sl.registerFactory<ProfileCompletionCubit>(
    () => ProfileCompletionCubit(completeProfile: sl<CompleteProfile>()),
  );

  sl.registerLazySingleton<UsagePolicy>(
    () => InMemoryUsagePolicy(
      tierLookup: (String userId) =>
          sl<auth_contract.AuthRepository>().getUserById(userId)?.tier ??
          SubscriptionTier.free,
    ),
  );

  sl.registerLazySingleton<DailyHoroscopeRemoteDataSource>(
    () => DailyHoroscopeRemoteDataSourceImpl(
      astroProvider: sl<AstroProvider>(),
      aiPersonalizer: sl<AiPersonalizer>(),
    ),
  );
  sl.registerLazySingleton<DailyHoroscopeRepository>(
    () => DailyHoroscopeRepositoryImpl(
      remoteDataSource: sl<DailyHoroscopeRemoteDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetPersonalizedDailyHoroscope>(
    () => GetPersonalizedDailyHoroscope(sl<DailyHoroscopeRepository>()),
  );
  sl.registerFactory<DailyHoroscopeBloc>(
    () => DailyHoroscopeBloc(
      getPersonalizedDailyHoroscope: sl<GetPersonalizedDailyHoroscope>(),
    ),
  );

  sl.registerLazySingleton<HoroscopeChatDataSource>(
    () => HoroscopeChatDataSourceImpl(aiPersonalizer: sl<AiPersonalizer>()),
  );
  sl.registerLazySingleton<HoroscopeChatRepository>(
    () => HoroscopeChatRepositoryImpl(
      dataSource: sl<HoroscopeChatDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<SendHoroscopeMessage>(
    () => SendHoroscopeMessage(sl<HoroscopeChatRepository>()),
  );
  sl.registerFactory<HoroscopeChatBloc>(
    () => HoroscopeChatBloc(
      sendHoroscopeMessage: sl<SendHoroscopeMessage>(),
      usagePolicy: sl<UsagePolicy>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );

  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(
      usagePolicy: sl<UsagePolicy>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      localDataSource: sl<HomeLocalDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetHomeDashboard>(
    () => GetHomeDashboard(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<RequestFeatureAccess>(
    () => RequestFeatureAccess(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GrantFeatureReward>(
    () => GrantFeatureReward(sl<HomeRepository>()),
  );
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      getHomeDashboard: sl<GetHomeDashboard>(),
      requestFeatureAccess: sl<RequestFeatureAccess>(),
      grantFeatureReward: sl<GrantFeatureReward>(),
    ),
  );

  sl.registerLazySingleton<KundliRemoteDataSource>(
    () => KundliRemoteDataSourceImpl(astroProvider: sl<AstroProvider>()),
  );
  sl.registerLazySingleton<KundliRepository>(
    () => KundliRepositoryImpl(
      remoteDataSource: sl<KundliRemoteDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetKundliInsight>(
    () => GetKundliInsight(sl<KundliRepository>()),
  );
  sl.registerFactory<KundliCubit>(
    () => KundliCubit(getKundliInsight: sl<GetKundliInsight>()),
  );

  sl.registerLazySingleton<MatchingRemoteDataSource>(
    () => MatchingRemoteDataSourceImpl(astroProvider: sl<AstroProvider>()),
  );
  sl.registerLazySingleton<MatchingRepository>(
    () => MatchingRepositoryImpl(
      remoteDataSource: sl<MatchingRemoteDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetMatchingResult>(
    () => GetMatchingResult(sl<MatchingRepository>()),
  );
  sl.registerFactory<MatchingCubit>(
    () => MatchingCubit(getMatchingResult: sl<GetMatchingResult>()),
  );

  sl.registerLazySingleton<NumerologyRemoteDataSource>(
    () => NumerologyRemoteDataSourceImpl(astroProvider: sl<AstroProvider>()),
  );
  sl.registerLazySingleton<NumerologyRepository>(
    () => NumerologyRepositoryImpl(
      remoteDataSource: sl<NumerologyRemoteDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetNumerologyInsight>(
    () => GetNumerologyInsight(sl<NumerologyRepository>()),
  );
  sl.registerFactory<NumerologyCubit>(
    () => NumerologyCubit(getNumerologyInsight: sl<GetNumerologyInsight>()),
  );

  sl.registerLazySingleton<GemstonesRemoteDataSource>(
    () => GemstonesRemoteDataSourceImpl(
      astroProvider: sl<AstroProvider>(),
      gemstoneEngine: sl<GemstoneEngine>(),
      aiPersonalizer: sl<AiPersonalizer>(),
    ),
  );
  sl.registerLazySingleton<GemstonesRepository>(
    () => GemstonesRepositoryImpl(
      remoteDataSource: sl<GemstonesRemoteDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetGemstoneInsight>(
    () => GetGemstoneInsight(sl<GemstonesRepository>()),
  );
  sl.registerFactory<GemstonesCubit>(
    () => GemstonesCubit(getGemstoneInsight: sl<GetGemstoneInsight>()),
  );

  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
    () =>
        SubscriptionRemoteDataSourceImpl(billingGateway: sl<BillingGateway>()),
  );
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
      remoteDataSource: sl<SubscriptionRemoteDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetSubscriptionOverview>(
    () => GetSubscriptionOverview(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<PurchaseSubscriptionPlan>(
    () => PurchaseSubscriptionPlan(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<RestoreSubscriptionPurchases>(
    () => RestoreSubscriptionPurchases(sl<SubscriptionRepository>()),
  );
  sl.registerFactory<SubscriptionCubit>(
    () => SubscriptionCubit(
      getSubscriptionOverview: sl<GetSubscriptionOverview>(),
      purchaseSubscriptionPlan: sl<PurchaseSubscriptionPlan>(),
      restoreSubscriptionPurchases: sl<RestoreSubscriptionPurchases>(),
    ),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetProfile>(
    () => GetProfile(sl<ProfileRepository>()),
  );
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(getProfile: sl<GetProfile>()),
  );

  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      localDataSource: sl<SettingsLocalDataSource>(),
      authRepository: sl<auth_contract.AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<GetSettingsPreferences>(
    () => GetSettingsPreferences(sl<SettingsRepository>()),
  );
  sl.registerLazySingleton<UpdatePushEnabled>(
    () => UpdatePushEnabled(sl<SettingsRepository>()),
  );
  sl.registerLazySingleton<UpdateLocalAiEnabled>(
    () => UpdateLocalAiEnabled(sl<SettingsRepository>()),
  );
  sl.registerLazySingleton<DeleteAccount>(
    () => DeleteAccount(sl<SettingsRepository>()),
  );
  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      getSettingsPreferences: sl<GetSettingsPreferences>(),
      updatePushEnabled: sl<UpdatePushEnabled>(),
      updateLocalAiEnabled: sl<UpdateLocalAiEnabled>(),
      deleteAccount: sl<DeleteAccount>(),
    ),
  );

  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(
      authBloc: sl<AuthBloc>(),
      profileCompletionCubitFactory: () => sl<ProfileCompletionCubit>(),
      dailyHoroscopeBlocFactory: () => sl<DailyHoroscopeBloc>(),
      homeCubitFactory: () => sl<HomeCubit>(),
      kundliCubitFactory: () => sl<KundliCubit>(),
      matchingCubitFactory: () => sl<MatchingCubit>(),
      numerologyCubitFactory: () => sl<NumerologyCubit>(),
      gemstonesCubitFactory: () => sl<GemstonesCubit>(),
      subscriptionCubitFactory: () => sl<SubscriptionCubit>(),
      profileCubitFactory: () => sl<ProfileCubit>(),
      settingsCubitFactory: () => sl<SettingsCubit>(),
    ),
    dispose: (AppRouter router) => router.dispose(),
  );
}
