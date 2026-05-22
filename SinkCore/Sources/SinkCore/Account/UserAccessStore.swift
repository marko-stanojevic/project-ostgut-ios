import Foundation
import Observation
import SinkAPI

@Observable
@MainActor
public final class UserAccessStore {
    public private(set) var access: UserAccess?

    public var isLicensed: Bool { access?.isLicensed ?? false }
    public var features: [String] { access?.features ?? [] }

    public var hasNativeAppAccess: Bool { access?.capabilities.canUseIOSApp ?? false }
    public var hasBrowserAccess: Bool { access?.capabilities.canUseBrowser ?? false }
    public var hasCoreAccess: Bool { access?.capabilities.canUseCore ?? false }
    public var hasMetadataAccess: Bool { access?.capabilities.canUseMetadata ?? false }

    private let fetcher: @Sendable () async throws -> UserAccess
    nonisolated(unsafe) private var periodicTask: Task<Void, Never>?

    public init(fetcher: @escaping @Sendable () async throws -> UserAccess) {
        self.fetcher = fetcher
        startPeriodicRefresh()
    }

    deinit {
        periodicTask?.cancel()
    }

    public func refresh() async {
        access = try? await fetcher()
    }

    public func clearAccess() {
        access = nil
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
