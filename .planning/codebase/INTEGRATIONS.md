# External Integrations

**Analysis Date:** 2026-04-16

## APIs & External Services

No external HTTP APIs or cloud services are integrated. The application is entirely offline/local.

## Authentication

**Auth Provider:** None detected.

- `lib/view/sign_in_page.dart` exists and is reachable via `/register` route, but no auth SDK (Firebase Auth, Supabase, OAuth, etc.) is present in `pubspec.yaml`.
- The sign-in page is likely a local player registration screen, not a remote authentication flow.

## Storage

**Local Key-Value Store:**
- `shared_preferences` ^2.5.3 via `lib/state/persistent_setting.dart`
- Stores: court background image path, game type (`timeBased`/`gameBased`), game duration (seconds), UI language (locale), auto-make-game flag
- Keys defined in `Setting` enum: `background`, `gameType`, `gameDuration`, `language`, `autoMakegame`

**Local File Storage (JSON):**
- `path_provider` ^2.1.5 resolves `getApplicationDocumentsDirectory()` as root storage path (`lib/repository/repository_service.dart`)
- `PlayerRepository` and `GameRepository` (`lib/repository/`) persist data as JSON files to the application documents directory
- Serialization/deserialization handled via `json_serializable`-generated `.g.dart` files

**File Import/Export:**
- `file_picker` ^10.2.0 — native OS file picker for reading/writing files (`lib/repository/serializer.dart`, `lib/core/importer.dart`)
- `csv` ^6.0.0 — CSV file parsing for bulk player import from spreadsheet exports (`lib/core/importer.dart`)
- JSON file import/export for data backup and restore (`lib/repository/serializer.dart`)

**Cloud Storage:** None.

## Infrastructure

**CI/CD:** GitHub Actions

- `.github/workflows/dart.yml` — Code quality pipeline triggered on push/PR to `main`
  - Steps: install deps → format check (`dart format`) → code generation (`build_runner`) → static analysis (`flutter analyze --fatal-infos`) → tests (`flutter test`)
  - Runs on: `ubuntu-latest`

- `.github/workflows/artifact.yml` — Windows release build triggered on push to `main` or `workflow_dispatch`
  - Steps: code generation → auto-tag via `mathieudutour/github-tag-action@v6.2` → `flutter build windows --dart-define=VERSION=<tag>` → zip artifact → publish GitHub Release
  - Runs on: `windows-latest`
  - Secret used: `GITHUB_TOKEN` (standard Actions token for release creation)

**Hosting:** GitHub Releases — Windows `.zip` artifact (`good_bad_board_window.zip`) published per tagged release.

**Environment Config:**
- `.env` file present at project root (not committed to git, contents not inspected)
- No runtime environment variable loading mechanism detected in Dart code; `.env` may be for local tooling only
- Build-time config injected via `--dart-define=VERSION=<ver>` in the artifact workflow

## Third-party SDKs

No third-party SDKs beyond `pub.dev` packages are integrated. All dependencies are pure Dart/Flutter packages with no native SDK wrappers (e.g., no Firebase, no Sentry, no Amplitude, no analytics SDK).

---

*Integration audit: 2026-04-16*
