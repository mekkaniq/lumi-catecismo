import SwiftUI

@main
struct LumiApp: App {
    @StateObject private var store = Store()
    @StateObject private var nav = Nav()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(nav)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var nav: Nav
    @Environment(\.dynamicTypeSize) private var systemSize

    private var size: DynamicTypeSize {
        let all = DynamicTypeSize.allCases
        let idx = all.firstIndex(of: systemSize) ?? 3
        let cap = all.firstIndex(of: .accessibility3) ?? (all.count - 1)
        return all[min(idx + store.d.fs * 2, cap)]
    }

    var body: some View {
        NavigationStack(path: $nav.path) {
            HubView()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
        }
        .environment(\.dynamicTypeSize, size)
        .onAppear { nav.applyLaunchArguments(store) }
    }

    @ViewBuilder
    private func destination(_ r: Route) -> some View {
        switch r {
        case .book(let id): BookView(book: Library.book(id))
        case .unit(let id, let u): UnitView(book: Library.book(id), u: u)
        case .study(let id, let u, let i): StudyView(book: Library.book(id), u: u, start: i)
        case .game: GameView()
        case .result: ResultView()
        case .classroom(let id, let u, let i): ClassView(startBook: id, startUnit: u, startIndex: i)
        case .text(let k): TextScreen(key: k)
        }
    }
}
