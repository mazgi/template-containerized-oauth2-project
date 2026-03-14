import Foundation

struct ItemResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let userId: String
    let createdAt: String
    let updatedAt: String
}
