# SINK FM — iOS

Native iOS app for the SINK FM curated radio platform.

- **iOS 17+**, universal (iPhone + iPad)
- **SwiftUI** with `@Observable`
- **Bundle ID**: `com.sinkfm.app`
- API client generated from the backend OpenAPI spec via Swift OpenAPI Generator

## Requirements

- Xcode 16+
- iOS 17 SDK
- [SwiftLint](https://github.com/realm/SwiftLint) (`brew install swiftlint`)
- A self-hosted macOS runner for pull request CI (see `.github/workflows/pr.yml`)

## Local setup

1. Clone this repo.
2. Open `SinkFM.xcodeproj` in Xcode.
3. Xcode resolves the local Swift packages (`SinkFMAPI`, `SinkFMPlayback`) automatically.
4. Select the `SinkFM` scheme and an iOS 17 simulator, then build (`⌘B`).
5. Set `API_BASE_URL` in `SinkFM/Config/Debug.xcconfig` to point at your local backend (`http://localhost:8080`).

## Packages

| Package | Purpose |
|---|---|
| `SinkFMAPI` | Generated API client (Swift OpenAPI Generator) + `APIClient` wrapper |
| `SinkFMPlayback` | `PlaybackService` protocol + `AVPlayerPlaybackService` implementation |

## API spec sync

When the backend API spec changes, an automated PR is opened in this repo by the `spec-sync.yml` workflow (see `ios-2`). Review the diff and merge — the next build regenerates the client automatically.

To set up the dispatch token: add a GitHub fine-grained PAT with `contents: write` on this repo to the web monorepo as the `SINKFM_IOS_DISPATCH_TOKEN` secret.

## CI

Pull request CI runs on a self-hosted macOS runner:

```
xcodebuild build-for-testing -scheme SinkFM -destination "platform=iOS Simulator,name=iPhone 16"
xcodebuild test -scheme SinkFM -destination "platform=iOS Simulator,name=iPhone 16"
swiftlint --strict
```

Distribution to TestFlight and the App Store is handled by Xcode Cloud (configured in Xcode, not YAML).

## Architecture

Feature directories inside the `SinkFM` app target:

```
SinkFM/
├── Core/           # App entry point, dependency container, navigation, theme
├── Features/
│   ├── Catalog/    # Station list, station detail, search
│   ├── Player/     # Mini-player, Now Playing screen, playback state
│   ├── Auth/       # Login, signup, Sign in with Apple
│   └── Account/    # Subscription status, upgrade prompt, logout
SinkFMAPI/          # Local Swift package — generated API client
SinkFMPlayback/     # Local Swift package — PlaybackService protocol + AVPlayer impl
```

View models are `@Observable` classes injected via `@Environment`. The app entry point constructs and injects `PlaybackService`, `APIClient`, `TokenStore`, and `UserAccessStore`.
