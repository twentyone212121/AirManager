import Foundation
import SQLite
import Vapor

struct Flight: Content {
    var date: String
    let fromIata: String
    let fromDate: Date
    let toIata: String
    let toDate: Date
    var duration: Double
    let freeSeats: Int
    let number: Int
    let price: Double
    
    mutating func afterDecode() throws {
        // Check if date is not provided, generate a default date (e.g., today)
        if self.date.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.date = dateFormatter.string(from: self.fromDate)
        }

        // Check if duration is not provided, calculate it based on fromDate and toDate
        if self.duration == 0 {
            self.duration = self.toDate.timeIntervalSince(self.fromDate) / 3600 // Duration in hours
        }
    }
}

class DatabaseManager {
    public var db: Connection!

    public var countries: CountriesTable!
    public var airports: AirportsTable!
    public var flights: FlightsTable!
    public var users: UsersTable!
    public var tickets: TicketsTable!
    
    init() {
        do {
            let path = "Resources/airmanager.sqlite3"
            db = try Connection(path)
            countries = CountriesTable(db: db)
            flights = FlightsTable(db: db)
            users = UsersTable(db: db)
            tickets = TicketsTable(db: db)
            airports = AirportsTable(db: db)
        } catch {
            print("Error initializing database: \(error)")
        }
    }
    
    func getCountryIso2(countryName: String) -> String? {
        let query = countries.table
            .where(countries.nameColumn == countryName)
            .select(countries.iso2Column)
        
        do {
            for row in try db.prepare(query) {
                return row[countries.iso2Column]
            }
        } catch {
            return nil
        }
        return nil
    }
    
    func getFlights(from: String, to: String) -> [Flight] {
        let query: QueryType
        if from.count == 3 && to.count == 3 {
             query = flights.table
                .where(flights.departureIataColumn == from &&
                       flights.arrivalIataColumn == to)
        } else {
            let departureAirport = airports.table.alias("departureAirport")
            let arrivalAirport = airports.table.alias("arrivalAirport")
            query = flights.table
                .join(departureAirport, on: flights.departureIataColumn == departureAirport[airports.iataColumn])
                .join(arrivalAirport, on: flights.arrivalIataColumn == arrivalAirport[airports.iataColumn])
                .filter(departureAirport[airports.cityColumn] == from)
                .filter(arrivalAirport[airports.cityColumn] == to)
                .select(flights.table[*])
        }
                
        var result: [Flight] = []
        do {
            for flight in try db.prepare(query) {
                result.append(Flight(
                    date: flight[flights.dateColumn],
                    fromIata: flight[flights.departureIataColumn],
                    fromDate: flight[flights.departureScheduledColumn],
                    toIata: flight[flights.arrivalIataColumn],
                    toDate: flight[flights.arrivalScheduledColumn],
                    duration: flight[flights.durationColumn],
                    freeSeats: flight[flights.freeSeatsColumn],
                    number: flight[flights.flightNumberColumn],
                    price: flight[flights.priceColumn]))
            }
        } catch {}
        return result
    }

    func addFlight(flight: Flight) throws {
        let query = flights.table
            .insert(
                flights.dateColumn <- flight.date,
                flights.priceColumn <- flight.price,
                flights.durationColumn <- flight.duration,
                flights.freeSeatsColumn <- flight.freeSeats,
                flights.arrivalIataColumn <- flight.toIata,
                flights.flightNumberColumn <- flight.number,
                flights.departureIataColumn <- flight.fromIata,
                flights.arrivalScheduledColumn <- flight.toDate,
                flights.departureScheduledColumn <- flight.fromDate)
        
        try db.run(query)
    }
    
//    func getUsers() -> [String: Int] {
//        var result: [String: Int] = [:]
//
//        do {
//            let usersTable = Table("users")
//            let name = Expression<String>("name")
//            let age = Expression<Int>("age")
//
//            for user in try db.prepare(usersTable) {
//                result[user[name]] = user[age]
//            }
//        } catch {
//            print("Error retrieving users: \(error)")
//        }
//
//        return result
//    }
}

