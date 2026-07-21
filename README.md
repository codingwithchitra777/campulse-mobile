# CamPulse Mobile

CamPulse Mobile is the Flutter-based mobile companion for the CamPulse platform.

## Implementation Plan (Web to Mobile Migration)

We are systematically migrating features from the CamPulse Web version to the Mobile App to ensure feature parity and identical premium visual design (custom floating navigation bars, dark themes, and glassmorphism).

### Step-by-Step Roadmap:
1. **[x] Dashboard (Guest & Authenticated)**
   - Match the web layout exactly (hiding empty charts for guests, showing "Locked" states).
   - Implement floating glassmorphism bottom navigation bar (5-slot layout: Dashboard, Portfolio, Trade, Learn, Account).
2. **[ ] Portfolio**
   - Implement user portfolio summary, charts, and holdings breakdown.
3. **[ ] Trade (Ledger/History)**
   - Implement buy/sell trade forms and historical trade ledger.
4. **[ ] Learn**
   - Implement educational modules and resources view.
5. **[ ] Account / Profile**
   - Implement user settings, preferences, and Google Sign-Out.

## Google Sign-In Setup for Local Development
- The app uses `google_sign_in` v7.2.0+. 
- On web/chrome, `serverClientId` must be conditionally omitted or it will throw an assertion error.
- Ensure the Flutter web app runs on a fixed port (e.g., `flutter run -d chrome --web-port=5555`) and that the exact origin is whitelisted in Google Cloud Console's OAuth 2.0 Authorized JavaScript Origins.
