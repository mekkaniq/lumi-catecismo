import SwiftUI

@main
struct LumiApp: App {
    @StateObject private var store = Store()
    @StateObject private var nav = Nav()
    @StateObject private var aulas = AulaStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(nav)
                .environmentObject(aulas)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var nav: Nav
    @EnvironmentObject private var aulas: AulaStore
    @State private var opening = false
    @State private var openError: String?
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
        .onAppear { nav.applyLaunchArguments(store, aulas: aulas) }
        // Arquivo aberto de fora (WhatsApp, Arquivos, e-mail): .vvaula, .pptx ou .pdf vira aula.
        .onOpenURL { url in
            guard url.isFileURL else { return }
            opening = true
            Task {
                do {
                    let a = try await AulaImport.newAula(from: url, store: aulas)
                    nav.path = [.aulas, .aula(a.id)]
                } catch { openError = error.localizedDescription }
                opening = false
            }
        }
        .overlay { if opening { BusyOverlay(text: "Abrindo a aula…") } }
        .alert("Não consegui abrir", isPresented: Binding(get: { openError != nil }, set: { if !$0 { openError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(openError ?? "") }
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
        case .aulas: AulasView()
        case .aula(let id): AulaEditView(id: id)
        }
    }
}
