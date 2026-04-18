import Foundation

enum GecitRuntimeState: String, Codable {
    case onboarding
    case stopped
    case starting
    case running
    case stopping
    case error
}

struct GecitStatus: Codable {
    let state: GecitRuntimeState
    let pid: Int?
    let message: String
    let updatedAt: String

    static let empty = GecitStatus(state: .onboarding, pid: nil, message: "Hazırlanıyor", updatedAt: "")
}
