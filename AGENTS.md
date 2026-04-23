# AGENTS.md

## Scope

This repository is a Flutter app using `GetIt + GoRouter + flutter_bloc` with a feature-first, clean-architecture-style layout.

Keep changes small and local. Follow the existing slice structure before introducing new patterns.

## Working Rules

- Read the relevant feature slice before editing.
- Keep feature code inside `lib/features/<feature>/`.
- Keep shared code in `lib/core/` or `lib/app/`.
- Register new dependencies in `lib/core/di/injection.dart`.
- Register new routes in `lib/app/router/app_router.dart`.
- Reuse `lib/app/theme/app_theme.dart` and shared widgets in `lib/core/widgets/` before creating new UI primitives.
- Run `flutter analyze` and the relevant `flutter test` targets after changes.
- Do not add more hard-coded sample birth details, partner details, quotas, or mock-only UI logic unless the task is explicitly a stub.

## Architecture

Preferred flow:

`Page/Widget -> Cubit/Bloc -> UseCase -> Repository (domain) -> RepositoryImpl (data) -> DataSource -> Core service/gateway`

Feature layout:

```text
lib/features/<feature>/
  data/
    datasources/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    cubit/ or bloc/
    <feature>_page.dart
```

Conventions used in this repo:

- Use `Cubit` for simple load/update flows.
- Use `Bloc` when the feature is event-driven or stream-driven, such as `auth`, `daily_horoscope`, and future chat flows.
- Keep repository contracts in `domain/repositories/`.
- Keep repository implementations in `data/repositories/`.
- Keep external/local IO in data sources only.
- Return domain entities from repositories.
- Use `Equatable` for entities and state.
- Use small use-case classes such as `GetProfile`, `GetKundliInsight`, `UpdatePushEnabled`.
- Throw `Failure` subclasses from repository boundaries when the UI needs a user-facing error.

Important project-specific note:

- New state management files should live under `presentation/cubit` or `presentation/bloc`.
- `lib/features/auth/bloc/` is an existing exception. Do not treat that root-level `bloc` folder as the pattern for new features.
- `lib/features/daily_horoscope/bloc/daily_horoscope_bloc.dart` is only an export shim. The actual implementation is under `presentation/bloc/`.

## Current Structure

Implemented feature slices:

- `auth`
- `home`
- `daily_horoscope`
- `kundli`
- `matching`
- `numerology`
- `gemstones`
- `subscription`
- `profile`
- `settings`
- `ui_preview`

Shared app structure:

- App bootstrap: `lib/main.dart`, `lib/app/astro_daily_app.dart`
- Routing: `lib/app/router/app_router.dart`
- Dependency injection: `lib/core/di/injection.dart`
- Shared contracts/gateways: `lib/core/services/contracts.dart`
- Shared visual system: `lib/app/theme/app_theme.dart`, `lib/core/widgets/*`

Routing pattern in this repo:

- Routed feature pages usually receive their `Cubit`/`Bloc` from `AppRouter`.
- Screen-local form state can be provided inside the page itself, as done in login/signup.

## Plan vs Current Code

The codebase is a partial implementation of `astro-daily-plan.md`, not the full product.

Missing or incomplete relative to the plan:

- `features/horoscope_chat/` does not exist yet. The daily horoscope page only contains a placeholder chat card.
- Ads are not implemented. There is no `AdGateway` yet for rewarded/banner/native flows.
- Billing is still mock-backed through `MockBillingGateway`.
- Astrology, gemstone, and AI behavior still come from `lib/core/services/mock_services.dart`.
- There is no real Prokerala, Supabase Edge Function, or `flutter_local_ai` integration yet.
- `UsagePolicy` is still in-memory and boolean; it does not model the planned access states of `open`, `reward_unlock_available`, and `premium_required`.
- The current quota policy does not match the plan. Example: daily horoscope is limited in code but planned as free and unlimited.
- `settings` preferences are in-memory only.
- Feature usage, report cache, ad rewards, and chat history persistence are not implemented.
- Full localization is not set up yet; current locale handling is only partial.
- Test coverage is strongest for `auth` and `daily_horoscope`; the rest of the slices are lightly or not yet tested.

Current data-quality gap:

- Several feature repositories still build `BirthDetails` from hard-coded sample values.
- New work should derive birth data from the authenticated user profile instead of adding more literals.

## How To Structure New Work

When adding or extending a feature:

- Start in the existing feature slice if one already exists.
- Add a new slice only when the behavior is truly its own module.
- Keep UI composition in `presentation`, business rules in `domain`, and IO in `data`.
- If the page becomes large, add `presentation/widgets/` inside that feature.

For planned work that is still missing:

- `horoscope_chat` should be its own feature slice with its own `presentation`, `domain`, and `data` layers.
- Ad and billing integrations should stay behind core gateway contracts, then be injected through `lib/core/di/injection.dart`.
- Access-control logic should stay centralized in policy/repository layers, not spread across widgets.
- If multiple astrology features need the same user-to-`BirthDetails` mapping, add a small shared mapper/helper instead of duplicating logic.

## File Touch Guide

- New feature logic: `lib/features/<feature>/...`
- New route or page entry: `lib/app/router/app_router.dart`
- New dependency registration: `lib/core/di/injection.dart`
- Shared gateway/policy/model changes: `lib/core/services/`, `lib/core/policy/`, `lib/core/models/`
- Shared UI changes: `lib/app/theme/`, `lib/core/widgets/`
- Tests: mirror the `lib/` structure under `test/features/...`

Special cases:

- `lib/features/ui_preview/presentation/ui_preview_page.dart` is a design reference surface, not product logic.
- `lib/core/widgets/astro_drawer.dart` is shared navigation UI, not a feature slice.

## Delivery Checklist

- Follow the existing feature slice and naming pattern.
- Update DI and routing when adding new feature entry points.
- Keep mocks separate from real integrations.
- Prefer extending the existing visual language instead of inventing a new one.
- Add or update tests for changed business logic.
- Finish by running `flutter analyze` and relevant tests.
