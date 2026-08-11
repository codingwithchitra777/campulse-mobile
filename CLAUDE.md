# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`campulse-mobile` is the **Flutter** companion app for CamboPulse (Cambodia-focused trading journal / portfolio tracker), package id `com.cambopulse.app`. It talks to the same FastAPI backend as the web app (sibling repo `campulse-backend`/`cambopulse-api`) at `https://api.cambopulse.com` — see that repo's CLAUDE.md for the API/data model. It is a **UI-parity port of `campulse-web`**: when adding a feature, check how the Angular app already did it (same endpoints, same field names, same rules) rather than designing it fresh. `agents.md` and `README.md` track the migration roadmap and Google Sign-In gotchas — read them too.

## Commands

```bash
flutter pub get                          # install dependencies
flutter run                              # run on a connected device/emulator
flutter run -d chrome --web-port=5555    # web dev — MUST use this fixed port (see Gotchas)
flutter test                             # run all tests
flutter test test/widget_test.dart       # run a single test file
flutter analyze                          # lint (flutter_lints, see analysis_options.yaml)
```

Localization: edit `lib/l10n/app_en.arb` (+ `app_km.arb`), then run `flutter gen-l10n` (or just `flutter run`, which regenerates `lib/l10n/app_localizations*.dart` automatically since `generate: true` in `pubspec.yaml`) — never hand-edit the generated `app_localizations_*.dart` files.

## Gotchas

- **Google Sign-In (v7.2.0+ API)**: use `GoogleSignIn.instance.authenticationEvents.listen(...)`, not the deprecated `onCurrentUserChanged`; trigger login with `GoogleSignIn.instance.authenticate()`, not `signIn()`. Do **not** pass `serverClientId` when `kIsWeb` — the web package asserts on it (see `services/auth_service.dart`, which branches `clientId` vs `serverClientId` on `kIsWeb`).
- Local web testing must run on a **fixed port** (`flutter run -d chrome --web-port=5555`); a random port won't match the origins whitelisted in Google Cloud Console and the OAuth flow fails with "Origin Mismatch".
- `widgets/google_sign_in_button.dart` is a **conditional-export shim** (`stub` vs `_web` implementation picked by `dart.library.html`) — if the sign-in button needs a platform-specific tweak, edit the matching `_stub`/`_web` file, not the shim.

## Architecture

No state-management package (no provider/riverpod/bloc) — plain `ValueNotifier`/`ChangeNotifier` singletons plus `StatefulWidget` + `setState`:

- **`ApiService`** (`services/api_service.dart`) — singleton HTTP client, hardcoded `baseUrl`. Holds `activeUserId` and the backend-issued `authToken`; every authed request sends both `Authorization: Bearer <token>` and `X-User-Id` (the backend's `get_current_user` verifies the JWT — `X-User-Id` alone now 401s). Mirrors `campulse-web`'s `ApiService` method-for-method; when the backend gains an endpoint, add the matching typed method here using the same field names as `campulse-web/src/app/models.ts`.
- **`AuthService`** (`services/auth_service.dart`) — singleton owning `profile: ValueNotifier<GoogleProfile?>` (null = guest). Wires Google Sign-In → `POST /api/auth/google` → `GoogleProfile` (userId/name/email/photoUrl/token), persists it to `shared_preferences` (`google_profile` key) so the session survives a restart, and pushes `activeUserId`/`authToken` into `ApiService`. Also has `loginAsDemo()` (mirrors the web "Continue as Guest" demo backdoor, hits `/api/auth/demo`).
- **`ThemeController`** / **`LocaleController`** (`theme/`) — singleton `ChangeNotifier`s for dark/light mode and EN/KM locale, both restored from `shared_preferences` during the `_bootstrap()` gate in `main.dart` before the first frame builds (`MaterialApp` is otherwise a spinner).
- **App shell** (`main.dart`): `MainLayout` is an `IndexedStack` of 5 screens (Dashboard, Portfolio, Add Trade, Watchlist, History) driven by a custom glassmorphism `_FloatingNav` (not the Material `BottomNavigationBar`), with a center `_RecordFab`. Screens are keyed by `ValueKey('<page>_$userId')` (`userId` = `'guest'` when signed out) so a login/logout **recreates** the widget and its `initState` re-fetches — this is the app's equivalent of the web app's `rxResource`-on-`activeUserId()` reactivity; don't add manual refresh plumbing around a login change, just make sure the screen keys off `userId`. Portfolio/Add Trade/Watchlist are wrapped in `guarded()`, which swaps in `LoginScreen` for guests.
- **`utils/markets.dart`** — `Market` enum (`csx`/`us`/`gold`) mirroring the backend's `services/markets.py`: backend code string, currency, price-decimal precision. Keep in sync if the backend adds a market.
- **`utils/money.dart`** — currency-aware formatting, the mobile equivalent of web's `MoneyPipe`; **never hardcode "riel"** — format KHR/USD amounts through it.
- **Multi-currency, never blended**: like the web app, per-currency figures (portfolio totals, yearly realized P/L, loan summaries) render as separate rows per currency — don't sum KHR and USD together.

## Verifying a change

There's no mocked test backend — `flutter test` only covers the one widget smoke test (`test/widget_test.dart`). For real verification, run the app (`flutter run`, or `-d chrome --web-port=5555` for web) against the live backend and check the flow manually.
