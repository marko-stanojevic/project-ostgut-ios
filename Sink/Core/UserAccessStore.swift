import Foundation
import Observation
import SinkAPI
#if os(iOS)
import UIKit
#endif

@Observable
@MainActor
final class UserAccessStore {
    private(set) var access: UserAccess?

    var isLicensed: Bool { access?.isLicensed ?? false }
    var features: [String] { access?.features ?? [] }

    var hasIOSAppAccess: Bool { access?.capabilities.canUseIOSApp ?? false }
    var hasBrowserAccess: Bool { access?.capabilities.canUseBrowser ?? false }
    var hasCoreAccess: Bool { access?.capabilities.canUseCore ?? false }
    var hasMetadataAccess: Bool { access?.capabilities.canUseMetadata ?? false }

    private let fetcher: @Sendable () async throws -> UserAccess
    nonisolated(unsafe) private var periodicTask: Task<Void, Never>?
#if os(iOS)
    nonisolated(unsafe) private var foregroundObserver: (any NSObjectProtocol)?
#endif

    init(fetcher: @escaping @Sendable () async throws -> UserAccess) {
        self.fetcher = fetcher
        setupForegroundRefresh()
        startPeriodicRefresh()
    }

    deinit {
#if os(iOS)
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
#endif
        periodicTask?.cancel()
    }

    // MARK: - Public API

    func refresh() async {
        access = try? await fetcher()
    }

    func clearAccess() {
        access = nil
    }

    // MARK: - Private

    private func setupForegroundRefresh() {
#if os(iOS)
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
#endif
    }

    private func startPeriodicRefresh() {
        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }
}
