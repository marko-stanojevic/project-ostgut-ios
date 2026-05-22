import SinkCore
import SwiftUI

struct RootView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(UserAccessStore.self) private var userAccessStore

    var body: some View {
        if navigation.isAuthenticated {
            if userAccessStore.access == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if userAccessStore.hasNativeAppAccess {
                MainTabView()
            } else {
                UpgradeView()
            }
        } else {
            MainTabView()
        }
    }
}
