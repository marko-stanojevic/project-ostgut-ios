# SINK — iOS

Native iOS app for the SINK curated radio platform (sink.fm).

- **iOS 17+**, universal (iPhone + iPad)
- **SwiftUI** with `@Observable`
- **Bundle ID**: `fm.sink.app`
- API client generated from the backend OpenAPI spec via Swift OpenAPI Generator

## Requirements

- Xcode 16+
- iOS 17 SDK
- [SwiftLint](https://github.com/realm/SwiftLint) (`brew install swiftlint`)
- A self-hosted macOS runner for pull request CI (see `.github/workflows/pr.yml`)

## Local setup

1. Clone this repo.
2. Open `Sink.xcodeproj` in Xcode.
3. Xcode resolves the local Swift packages (`SinkAPI`, `SinkPlayback`) automatically.
4. Select the `Sink` scheme and an iOS 17 simulator, then build (`⌘B`).
5. Set `API_BASE_URL` in `Sink/Config/Debug.xcconfig` to point at your local backend (`http://localhost:8080`).

## Packages

| Package | Purpose |
|---|---|
| `SinkAPI` | Generated API client (Swift OpenAPI Generator) + `APIClient` wrapper |
| `SinkPlayback` | `PlaybackService` protocol + `AVPlayerPlaybackService` implementation |

## API spec sync

When the backend API spec changes on `main`, the backend CI automatically opens a PR in this repo with the updated `SinkAPI/Sources/SinkAPI/openapi.yaml`. Review the diff and merge — the next build regenerates the client. Breaking changes surface as compile errors.

### One-time token setup

Create a single GitHub fine-grained PAT with:
- **`contents: write`** on `project-ostgut-ios` (allows the backend CI to dispatch here)
- **`contents: read`** on `project-ostgut` (allows this repo's workflow to fetch the spec)

Add it in two places:
1. `project-ostgut` repo → Settings → Secrets → **`OSTGUT_IOS_DISPATCH_TOKEN`**
2. `project-ostgut-ios` repo → Settings → Secrets → **`OSTGUT_IOS_DISPATCH_TOKEN`**

## CI

Pull request CI runs on a self-hosted macOS runner:

```
xcodebuild build-for-testing -scheme Sink -destination "platform=iOS Simulator,name=iPhone 16"
xcodebuild test -scheme Sink -destination "platform=iOS Simulator,name=iPhone 16"
swiftlint --strict
```

Distribution to TestFlight and the App Store is handled by Xcode Cloud (configured in Xcode, not YAML).

## Architecture

Feature directories inside the `Sink` app target:

```
Sink/
├── Core/           # App entry point, dependency container, navigation, theme
├── Features/
│   ├── Catalog/    # Station list, station detail, search
│   ├── Player/     # Mini-player, Now Playing screen, playback state
│   ├── Auth/       # Login, signup, Sign in with Apple
│   └── Account/    # Subscription status, upgrade prompt, logout
SinkAPI/            # Local Swift package — generated API client
SinkPlayback/       # Local Swift package — PlaybackService protocol + AVPlayer impl
```

View models are `@Observable` classes injected via `@Environment`. The app entry point constructs and injects `PlaybackService`, `APIClient`, `TokenStore`, and `UserAccessStore`.
