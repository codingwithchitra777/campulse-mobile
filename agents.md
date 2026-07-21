# Mobile App Agent Rules & Memory

## Mobile UI & Styling
- **Web Parity**: The mobile app UI must exactly match the premium visual design of the web app. Use translucent, glass-like floating containers for bottom navigation (matching `.mobile-bottom-nav` on web).
- **Guest State**: When a user is not logged in (Guest), charts and sensitive data should be hidden and replaced with "Locked" states, just like the web dashboard. Remove default "Guest" header text.

## Google Sign-In Setup & Gotchas (v7.2.0+)
- **API Usage**: Use `GoogleSignIn.instance.authenticationEvents.listen(...)` to listen for sign-ins instead of the deprecated `onCurrentUserChanged`.
- **Triggering Login**: Use `GoogleSignIn.instance.authenticate()` to trigger login (instead of `signIn()`).
- **Web Compatibility**: Do NOT pass `serverClientId` to `initialize()` when running on the web (`kIsWeb`), otherwise the `google_sign_in_web` package will throw an assertion error.
- **Local Porting**: Always run local web testing with a fixed port (e.g., `flutter run -d chrome --web-port=5555`). Do not use random ports because the OAuth flow will fail with "Access blocked: Authorization Error" or "Origin Mismatch" (random ports won't match GCP authorized origins).

## Implementation Roadmap (Web to Mobile)
1. Dashboard (Guest & Authenticated) -> DONE
2. Portfolio
3. Trade (Ledger/History)
4. Learn
5. Account / Profile
