import Foundation
import SQLite
import Vapor

struct Flight: Content, Decodable {
    var date: String
    let fromIata: String
    var fromDate: Date
    let toIata: String
    var toDate: Date
    var duration: Double
    let freeSeats: Int
    let number: Int
    let price: Double
    
    enum CodingKeys: String, CodingKey {
        case fromIata
        case fromDate
        case toIata
        case toDate
        case freeSeats
        case number
        case price
        case duration
    }
    
    init(date: String, fromIata: String, fromDate: Date, toIata: String, toDate: Date, duration: Double, freeSeats: Int, number: Int, price: Double) {
        self.date = date
        self.fromIata = fromIata
        self.fromDate = fromDate
        self.toIata = toIata
        self.toDate = toDate
        self.duration = duration
        self.freeSeats = freeSeats
        self.number = number
        self.price = price
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.fromIata = try container.decode(String.self, forKey: .fromIata)
        self.toIata = try container.decode(String.self, forKey: .toIata)
        self.freeSeats = try container.decode(Int.self, forKey: .freeSeats)
        self.number = try container.decode(Int.self, forKey: .number)
        self.price = try container.decode(Double.self, forKey: .price)
        
        self.fromDate = Date()
        self.toDate = Date()
        self.date = ""
        self.duration = 0.0
        
        let fromDateString = try container.decode(String.self, forKey: .fromDate)
        if let fromDate = decodeDate(from: fromDateString) {
            self.fromDate = fromDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .fromDate, in: container, debugDescription: "Invalid date format")
        }
        
        let toDateString = try container.decode(String.self, forKey: .toDate)
        if let toDate = decodeDate(from: toDateString) {
            self.toDate = toDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .toDate, in: container, debugDescription: "Invalid date format")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.date = dateFormatter.string(from: self.fromDate)
        self.duration = self.toDate.timeIntervalSince(self.fromDate) / 3600
    }

    private func decodeDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return dateFormatter.date(from: dateString)
    }
}

enum DatabaseError: Error {
    case incorrectArguments
    case interalMalfunction
}

class DatabaseManager {
    public var db: Connection!

    public var countries: CountriesTable!
    public var airports: AirportsTable!
    public var flights: FlightsTable!
    public var users: UsersTable!
    public var tickets: TicketsTable!
    public var airplanes: AirplanesTable!
    
    init() {
        do {
            let path = "Resources/airmanager.sqlite3"
            db = try Connection(path)
            countries = CountriesTable(db: db)
            airports = AirportsTable(db: db)
            airplanes = AirplanesTable(db: db)
            
            flights = FlightsTable(db: db, airplanesNum: airplanes.amount)
          
            users = UsersTable(db: db)
            tickets = TicketsTable(db: db)
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
        var queryIata: QueryType
        queryIata = flights.table
        if !from.isEmpty {
            queryIata = queryIata.where(flights.departureIataColumn == from)
        }
        if !to.isEmpty {
            queryIata = queryIata.where(flights.arrivalIataColumn == to)
        }
        
        var queryCity: QueryType
        let departureAirport = airports.table.alias("departureAirport")
        let arrivalAirport = airports.table.alias("arrivalAirport")
        queryCity = flights.table
            .join(departureAirport, on: flights.departureIataColumn == departureAirport[airports.iataColumn])
            .join(arrivalAirport, on: flights.arrivalIataColumn == arrivalAirport[airports.iataColumn])
        
        if !from.isEmpty {
            queryCity = queryCity.filter(departureAirport[airports.cityColumn] == from)
        }
        if !to.isEmpty {
            queryCity = queryCity.filter(arrivalAirport[airports.cityColumn] == to)
        }
        
        let queries = [queryIata, queryCity]
        var result: [Flight] = []
        do {
            for query in queries {
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
            }
        } catch {}
        return result
    }

    func addFlight(flight: Flight) throws {
        let query = flights.table
            .insert(
                flights.dateColumn <- flight.date,
                flights.statusColumn <- "scheduled",
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
    
    func addTicket(loginData: LoginData, flightId: Int) throws {
        try db.transaction {
            // Check if there are available seats
            let availableSeats = try db.scalar(flights.table
                .filter(flights.idColumn == flightId)
                .select(flights.freeSeatsColumn)
            )
            if availableSeats <= 0 {
                throw DatabaseError.incorrectArguments
            }

            // Decrement freeSeatsColumn
            let updatedSeats = availableSeats - 1
            let updateStatement = flights.table
                .filter(flights.idColumn == flightId)
                .update(flights.freeSeatsColumn <- updatedSeats)
            try db.run(updateStatement)

            // Add a new row to the tickets table
            let insertStatement = tickets.table
                .insert(
                    tickets.flightIdColumn <- flightId,
                    tickets.emailColumn <- loginData.email)
            try db.run(insertStatement)
        }
    }
}

