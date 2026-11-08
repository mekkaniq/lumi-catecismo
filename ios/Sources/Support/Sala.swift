import Foundation

/// Conversa com a sala aberta no computador (site /aula): envia a aula e passa os slides.
/// O computador mostra um código de 6 dígitos; o celular entra com ele.
enum SalaAPI {
    static let base = URL(string: "https://tohphjpibyfikrmgswhk.supabase.co")!
    static let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRvaHBoanBpYnlmaWtybWdzd2hrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxMjYzODAsImV4cCI6MjEwOTcwMjM4MH0.pGoIL1m6unwubNwNBGhz7CzNynyfW-5yjPOrDOuSCZ0"
    static let site = "lumi-catecismo.vercel.app/aula"

    struct Info: Decodable {
        let existe: Bool
        let online: Bool
        let carregada: Bool
        let quadro: Int
        let arquivo: String?
    }

    enum Failure: LocalizedError {
        case noRoom, offline, http(Int)
        var errorDescription: String? {
            switch self {
            case .noRoom: return "Código não encontrado. Confira o número na tela do computador."
            case .offline: return "Sem conexão com a internet."
            case .http(let c): return "O servidor não respondeu (\(c)). Tente de novo."
            }
        }
    }

    private static func request(_ path: String, method: String = "POST", body: Data?, type: String = "application/json", timeout: TimeInterval = 20) -> URLRequest {
        var r = URLRequest(url: base.appendingPathComponent(path))
        r.httpMethod = method
        r.timeoutInterval = timeout
        r.setValue(key, forHTTPHeaderField: "apikey")
        r.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        r.setValue(type, forHTTPHeaderField: "Content-Type")
        r.httpBody = body
        return r
    }

    private static func send(_ r: URLRequest) async throws -> Data {
        do {
            let (d, resp) = try await URLSession.shared.data(for: r)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(code) else { throw Failure.http(code) }
            return d
        } catch let e as Failure {
            throw e
        } catch {
            throw Failure.offline
        }
    }

    static func info(_ code: String) async throws -> Info {
        let body = try JSONSerialization.data(withJSONObject: ["p_code": code])
        let d = try await send(request("rest/v1/rpc/sala_info", body: body, timeout: 10))
        guard let i = try JSONDecoder().decode([Info].self, from: d).first else { throw Failure.noRoom }
        return i
    }

    /// Envia o arquivo da aula para a sala e avisa o computador para carregar.
    static func upload(_ code: String, file: Data, startAt f: Int) async throws {
        try await broadcast(code, ["t": "hello"])
        let path = "salas/\(code)/\(UUID().uuidString.lowercased()).vvaula"
        _ = try await send(request("storage/v1/object/aulas/" + path, body: file, type: "application/zip", timeout: 120))
        let body = try JSONSerialization.data(withJSONObject: ["p_code": code, "p_arquivo": path])
        _ = try await send(request("rest/v1/rpc/sala_arquivo", body: body))
        try await broadcast(code, ["t": "load", "file": path, "f": f])
    }

    static func broadcast(_ code: String, _ payload: [String: Any]) async throws {
        let msg: [String: Any] = ["messages": [["topic": "sala-" + code, "event": "cmd", "payload": payload]]]
        _ = try await send(request("realtime/v1/api/broadcast", body: try JSONSerialization.data(withJSONObject: msg), timeout: 10))
    }
}
