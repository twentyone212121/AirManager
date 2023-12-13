import Foundation
import Vapor
import SQLite

struct Airplane: Content {
    let id: Int
    let model: String
}

extension DatabaseManager {
    func getAirplanes() -> [Airplane] {
        var result: [Airplane] = []
        let query = airplanes.table
        
        do {
            for row in try db.prepare(query) {
                result.append(Airplane(
                    id: row[airplanes.idColumn],
                    model: row[airplanes.modelColumn]))
            }
        } catch {
            print("Error getting airplanes \(error)")
        }
        return result
    }
}
