# SINK — iOS Agent Instructions

## What this app is

The SINK native app is the listener companion to the SINK radio platform (sink.fm, internal codename `project-ostgut`). It is listener-only — no editor or admin surfaces in the native app targets.

The repo now ships two app targets:
- `Sink` — the universal iOS target for both iPhone and iPad
- `SinkMac` — the native macOS 14+ app target

The app stack uses SwiftUI and `@Observable`. There is no separate iPad target.

## Required Completion Gate

Before reporting any item as complete, build both schemes, run the iOS tests, and lint:

```bash
xcodebuild build-for-testing -scheme Sink -destination "platform=iOS Simulator,name=iPhone 17" -skipPackagePluginValidation | xcpretty
xcodebuild build-for-testing -scheme SinkMac -destination "platform=macOS" -skipPackagePluginValidation | xcpretty
xcodebuild test -scheme Sink -destination "platform=iOS Simulator,name=iPhone 17" -skipPackagePluginValidation | xcpretty
swiftlint --strict
```

All commands must pass. A SwiftLint warning is a failure.

## Architecture

**SwiftUI + `@Observable`.** No third-party architecture frameworks.

**Dependency injection via `@Environment`.** The app entry points (`Sink/Core/SinkApp.swift` and `SinkMac/SinkMacApp.swift`) construct the dependency container and inject it into SwiftUI:
- `APIClient` — from `SinkAPI`
- `AVPlayerPlaybackService` — from `SinkPlayback`
- `AppNavigation` — from `SinkCore`
- `AuthViewModel` — from `SinkCore`
- `CatalogViewModel` — from `SinkCore`
- `SearchViewModel` — from `SinkCore`
- `UserAccessStore` — from `SinkCore`
- `PlayerPreferencesStore` — from `SinkCore`
- `TokenStore` — actor used by the app targets when constructing `APIClient`

**Three local Swift packages:**
- `SinkCore/` — shared stores, view models, and content views. Feature-based layout: `Auth/`, `Catalog/`, `Player/`, `Account/`, `Navigation/`. Targets iOS 17+ and macOS 14+. All shared surface area that crosses the package boundary must be `public`.
- `SinkAPI/` — generated API client (Swift OpenAPI Generator) plus the handwritten `APIClient` wrapper. Never add raw networking code to either app target.
- `SinkPlayback/` — `PlaybackService`, `AVPlayerPlaybackService`, playback models, and audio/runtime behavior shared by the app targets.

## App Target Structure

```text
Sink/                          # iOS + iPadOS universal target
├── Core/
│   ├── SinkApp.swift          # @main, dependency container
│   ├── RootView.swift         # Auth / access gate
│   └── AppShell.swift         # Adaptive NavigationSplitView shell
└── Config/

SinkMac/                       # Native macOS target
├── SinkMacApp.swift           # @main, dependency container, window + menu bar scenes
├── MacRootView.swift          # Auth / access gate for Mac
├── MacAppShell.swift          # Mac NavigationSplitView with persistent sidebar
├── MenuBarPlayerView.swift    # MenuBarExtra popover content
├── MenuBarIconView.swift      # Menu bar icon
└── Config/
```

Shared UI and state live in `SinkCore`, not in either app target.

## Navigation

Both app targets use `NavigationSplitView`.

- On iPhone, `NavigationSplitView` collapses to a navigation stack automatically in compact width.
- On iPad and Mac, it shows the sidebar and detail column.
- Do not add size-class branching or `#if` checks just to switch navigation containers. The platform behavior comes from the shared SwiftUI primitive.

Platform-specific shell behavior belongs in the app targets:
- `Sink/Core/AppShell.swift` owns the iOS/iPad layout and mini-player placement
- `SinkMac/MacAppShell.swift` owns the Mac sidebar layout

## API Client

All API calls go through `SinkAPI.APIClient`. Never call `URLSession` directly from `Sink` or `SinkMac`.

`APIClient` injects `Authorization: Bearer <token>` by calling `TokenStore.accessToken() async throws` before each request. `TokenStore` refreshes silently when the token is close to expiry.

The OpenAPI spec is committed at `SinkAPI/Sources/SinkAPI/openapi.yaml`. The Swift OpenAPI Generator plugin regenerates the client during builds. When the backend spec changes, merge the generated changes and rebuild.

## Playback

`AVPlayerPlaybackService` in `SinkPlayback` is the concrete playback implementation injected into both app targets.

- `play(station:)` resolves a signed playback URL from the backend, swaps the `AVPlayerItem`, and starts playback.
- `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` wiring lives in `SinkPlayback`, not in the app targets.
- Playback URL re-resolution and now-playing polling are playback-layer responsibilities.
- App and menu bar surfaces should control playback through the injected shared `PlaybackService` state, never through duplicate local player state.

## Subscription Gating

`UserAccessStore` owns the result of `GET /v1/users/me/access`.

- All app-access gating reads from `UserAccessStore`.
- Use `hasNativeAppAccess`, not `hasIOSAppAccess`.
- Never hardcode plan names or feature assumptions in the app targets.

The current gating model is:
- unauthenticated: show login flow over the shell
- authenticated without native access: show upgrade gating
- authenticated with native access: show the normal shell

## MenuBarExtra

`SinkMac` includes a menu bar scene in `SinkMacApp.swift`.

- Use `.menuBarExtraStyle(.window)` so the menu bar surface behaves as a popover panel, not a menu list.
- The menu bar scene shares the same `PlaybackService`, `UserAccessStore`, and other environment state as the main Mac window.
- `MenuBarPlayerView` stays intentionally minimal: station name, track metadata, play/pause, and open-main-window affordance.
- Tapping the station name opens or focuses the main window via `openWindow(id: "main")`.

## Authentication

`TokenStore` is a Swift actor. It owns access and refresh tokens and is used by the app targets when building `APIClient`.

Authentication surfaces themselves live in `SinkCore/Auth/`.

- Sign in with Apple uses the backend auth flow, not native-only token handling.
- Email/password login and registration also go through backend endpoints exposed by `SinkAPI`.

## Engineering Principles

- **SwiftLint is enforced with no warnings.** Treat warnings as failures.
- **No raw `URLSession` outside `SinkAPI`.**
- **No third-party dependencies** without explicit discussion.
- **Use `@Observable`, not `ObservableObject`, for app-owned observable state.**
- **Use `@Environment` for injected shared state.**
- **Shared code belongs in `SinkCore` unless it is truly platform-specific.**
- **Keep Mac-only and iOS-only view composition in the app targets.**

## Naming

Use the same domain vocabulary as the backend and shared packages:
- `CatalogEntry` is the catalog domain concept
- playback surfaces may still render stations, but do not invent parallel domain models
- feature keys come from the API and are not redefined as app-only enums without a strong reason

## CI

Pull request CI runs on a self-hosted macOS runner. The native validation contract is build, test, and lint for the current platform structure. Xcode Cloud handles distribution flows.

## Do Not

- Do not add `#if os(iOS)` inside `SinkCore`. Platform-specific code belongs in `Sink` or `SinkMac`.
- Do not duplicate stores or view models between targets. `SinkCore` is the single source of shared app state and shared surfaces.
- Do not add raw networking outside `SinkAPI`.
- Do not hardcode app access. Read `hasNativeAppAccess` from `UserAccessStore`.
- Do not commit `DerivedData/`, user data, or provisioning artifacts.
