import Foundation
import SQLite
import Vapor

struct FuelUsageRow: Content {
    let number: Int
    let from: String
    let to: String
    let duration: Double
    let fuelPerHour: Int
    let totalFuelConsumption: Int
}

extension DatabaseManager {
    func getFuelUsage(flightNumber: Int) -> [FuelUsageRow] {
        let f = flights.table
        let a = airplanes.table
        let query = f.join(a, on: f[flights.airplaneIdColumn] == a[airplanes.idColumn])
            .filter(f[flights.flightNumberColumn] == flightNumber)
        
        do {
            return try db.prepare(query).map { (row) -> FuelUsageRow in
                FuelUsageRow(
                    number: row[flights.flightNumberColumn],
                    from: row[flights.departureIataColumn],
                    to: row[flights.arrivalIataColumn],
                    duration: row[flights.durationColumn],
                    fuelPerHour: row[airplanes.fuelConsumptionColumn],
                    totalFuelConsumption: Int(Double(row[airplanes.fuelConsumptionColumn]) * row[flights.durationColumn])
                )
            }
        } catch {
            print("\(error)")
        }
        return []
    }
    
    func getFlightsFromAirport(departureIata: String) -> [Flight] {
        let query = flights.table.where(flights.departureIataColumn == departureIata)
        return getFlightsFromQueries(queries: [query])
    }
}
