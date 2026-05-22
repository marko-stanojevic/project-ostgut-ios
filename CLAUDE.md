# SINK — iOS Agent Instructions

## What this app is

The SINK iOS app is the native companion to the SINK radio platform (sink.fm, internal codename `project-ostgut`). It is a listener-only app — no editor or admin surfaces in v1. It targets iOS 17+ with SwiftUI and `@Observable`.

## Required Completion Gate

Before reporting any item as complete, build the scheme and run tests:

```bash
xcodebuild build-for-testing -scheme Sink -destination "platform=iOS Simulator,name=iPhone 17" -skipPackagePluginValidation | xcpretty
xcodebuild test -scheme Sink -destination "platform=iOS Simulator,name=iPhone 17" -skipPackagePluginValidation | xcpretty
swiftlint --strict
```

All three must pass. A SwiftLint warning is a failure.

## Architecture

**SwiftUI + `@Observable` (iOS 17+).** No third-party architecture frameworks.

**Dependency injection via `@Environment`.** The app entry point (`SinkApp.swift` in `Core/`) constructs the dependency container and injects into the SwiftUI environment:
- `PlaybackService` — from `SinkPlayback` package
- `APIClient` — from `SinkAPI` package
- `TokenStore` — actor, lives in `Core/`
- `UserAccessStore` — `@Observable`, lives in `Core/`

**Two local Swift packages:**
- `SinkAPI/` — generated API client (Swift OpenAPI Generator) + `APIClient` wrapper. Never add handwritten networking code to the app target.
- `SinkPlayback/` — `PlaybackService` protocol + `AVPlayerPlaybackService`. The protocol is the only playback dependency the app target and future CarPlay extension share.

## App target structure

```
Sink/
├── Core/
│   ├── SinkApp.swift            # @main, dependency container
│   ├── AppNavigation.swift      # NavigationPath / coordinator
│   └── Theme/                   # Typography, colours, spacing tokens
├── Features/
│   ├── Catalog/                 # Station list, station detail, search
│   ├── Player/                  # Mini-player, Now Playing screen
│   ├── Auth/                    # Login, signup, Sign in with Apple
│   └── Account/                 # Subscription status, upgrade prompt, logout
├── Config/
│   ├── Debug.xcconfig
│   └── Release.xcconfig
└── Resources/                   # Assets.xcassets, Info.plist, etc.
```

## API client

All API calls go through `SinkAPI.APIClient`. Never call `URLSession` directly from the app target.

`APIClient` injects `Authorization: Bearer <token>` by calling `TokenStore.accessToken() async throws` before each request. `TokenStore` refreshes silently when the token is within 60 seconds of expiry.

The spec is committed at `SinkAPI/Sources/SinkAPI/openapi.yaml`. The Swift OpenAPI Generator plugin regenerates the client at every build. When the backend spec changes, the `spec-sync.yml` workflow opens a PR — review and merge it, then build to regenerate.

## Playback

`AVPlayerPlaybackService` (in `SinkPlayback`) is the concrete `PlaybackService`.

- `play(station:)` calls `GET /v1/catalog/:id/playback`, creates an `AVPlayerItem`, and calls `AVPlayer.replaceCurrentItem`. It must set `AVAudioSession` category to `.playback` before the first `play()` call.
- Playback URLs are short-lived signed redirects. Track `expires_at` and re-resolve before it elapses. After network interruption, always re-resolve — never retry a stale URL.
- `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` are wired in `AVPlayerPlaybackService`.
- Interruption handling: resume playback after `AVAudioSession.interruptionNotification` ends with `.shouldResume`.

## Subscription gating

`UserAccessStore` holds the result of `GET /v1/users/me/access`. All gates in the UI read from `UserAccessStore` — never hardcode plan names or assume which plan grants which feature. The `ios_app_access` feature key gates access to the app itself; check it on launch.

## Authentication

`TokenStore` is a Swift actor. It owns access and refresh tokens in the Keychain. Expose `accessToken() async throws -> String` — callers never touch the raw token.

Sign in with Apple sends the identity token to `POST /v1/auth/oauth` with `provider: "apple"`. Email/password login uses `POST /v1/auth/login`. Registration uses `POST /v1/auth/register`.

## Engineering principles

- **SwiftLint is enforced with no warnings.** Treat a warning as a build failure.
- **No raw URLSession outside `SinkAPI`.** If a new API call is needed, add it to the spec and let the generator produce the client code.
- **No third-party dependencies** without explicit discussion. The only external dependencies are the three Apple-maintained Swift OpenAPI packages.
- **Tests use Swift Testing** (`@Test`, `@Suite`) not XCTest where possible. Mocks use Swift protocols — no third-party mocking frameworks.
- **`@Observable` view models, not `ObservableObject`.** Never add `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` — use `@State` for owned view models and `@Environment` for injected ones.
- **No `force_unwrapping` (`!`).** SwiftLint enforces this. Use `guard let`, `if let`, or throw.

## CI

Pull request CI runs on a self-hosted macOS runner via `.github/workflows/pr.yml`. It builds, tests, and lints. Xcode Cloud handles TestFlight and App Store distribution (configured in Xcode, not YAML).

## Naming

Use the same domain vocabulary as the backend: `CatalogEntry` (not "station" as a type name), `slug`, `overview`, `staffPick`. Feature keys like `ios_app_access` are strings from the API — do not redefine them as Swift enums unless there is an exhaustive list.

## Do not

- Do not add `ObservableObject` / Combine to new code — use `@Observable`
- Do not commit `.xcworkspace/xcuserdata/`, `DerivedData/`, or `*.mobileprovision`
- Do not hardcode `https://api.sink.fm` — read from the xcconfig `API_BASE_URL`
- Do not cache playback URLs across sessions or after a network interruption
- Do not approve or auto-grant `ios_app_access` — read it from `UserAccessStore`
