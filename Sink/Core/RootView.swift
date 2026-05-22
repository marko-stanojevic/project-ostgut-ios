import SinkCore
import SwiftUI

struct RootView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(UserAccessStore.self) private var userAccessStore

    var body: some View {
        AppShell()
            .sheet(isPresented: authSheetPresented) {
                LoginView()
            }
            .fullScreenCover(isPresented: upgradePresented) {
                UpgradeView()
            }
    }

    private var authSheetPresented: Binding<Bool> {
        Binding(
            get: { !navigation.isAuthenticated },
            set: { _ in }
        )
    }

    private var upgradePresented: Binding<Bool> {
        Binding(
            get: {
                navigation.isAuthenticated &&
                    userAccessStore.access != nil &&
                    !userAccessStore.hasNativeAppAccess
            },
            set: { _ in }
        )
    }
}
