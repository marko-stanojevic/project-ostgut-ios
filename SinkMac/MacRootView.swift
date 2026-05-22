import SinkCore
import SwiftUI

struct MacRootView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(UserAccessStore.self) private var userAccessStore

    var body: some View {
        MacAppShell()
            .sheet(isPresented: authSheetPresented) {
                LoginView()
                    .frame(minWidth: 400, minHeight: 500)
            }
            .sheet(isPresented: upgradePresented) {
                UpgradeView()
                    .frame(minWidth: 420, minHeight: 520)
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
