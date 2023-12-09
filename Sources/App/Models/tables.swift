import Foundation
import SQLite

struct CountriesTable {
    let table = Table("countries")

    let nameColumn = Expression<String>("name")
    let iso2Column = Expression<String>("iso2")
    let iso3Column = Expression<String>("iso3")
    let populationColumn = Expression<Int>("population")
    let capitalColumn = Expression<String>("capital")
    let continentColumn = Expression<String>("continent")
    
    init(db: Connection) {
        do {
//            try db.run(table.drop(ifExists: true))
            try db.run(table.create() { table in
                table.column(nameColumn)
                table.column(iso2Column, unique: true, check: iso2Column.length == 2)
                table.column(iso3Column, unique: true, check: iso3Column.length == 3)
                table.column(populationColumn)
                table.column(capitalColumn)
                table.column(continentColumn)
            })
        } catch {
            print("Error initializing table: \(error)")
            return
        }
        
        do {
            try loadFromCsv(db: db)
        } catch {
            print("Error loading from CSV: \(error)")
        }
    }
    
    func loadFromCsv(db: Connection) throws {
        print("Loading from CSV.")
        let csvFileURL = "Resources/CsvData/countries.csv"

        let data = try String(contentsOfFile: csvFileURL)
        let rows = data.components(separatedBy: "\n").dropFirst()

        for row in rows {
            let columns = row.components(separatedBy: ",")
            if columns.count >= 7 {
                let name = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let iso2 = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let iso3 = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let population = Int(columns[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                let capital = columns[5].trimmingCharacters(in: .whitespacesAndNewlines)
                let continent = columns[6].trimmingCharacters(in: .whitespacesAndNewlines)

                let insert = table.insert(
                    nameColumn <- name,
                    iso2Column <- iso2,
                    iso3Column <- iso3,
                    populationColumn <- population,
                    capitalColumn <- capital,
                    continentColumn <- continent)
                try db.run(insert)
            }
        }
    }
}

struct FlightsTable {
    let table = Table("flights")

    //flight_date,flight_status,departure.iata,departure.scheduled,arrival.iata,arrival.scheduled,flight.number,aircraft
    let idColumn = Expression<Int>("id")
    let dateColumn = Expression<String>("date")
    let statusColumn = Expression<String>("status")
    let departureIataColumn = Expression<String>("departureIata")
    let departureScheduledColumn = Expression<Date>("departureScheduled")
    let arrivalIataColumn = Expression<String>("arrivalIata")
    let arrivalScheduledColumn = Expression<Date>("arrivalScheduled")
    let flightNumberColumn = Expression<Int>("flightNumber")
    let durationColumn = Expression<Double>("duration")
    let freeSeatsColumn = Expression<Int>("freeSeats")
    let priceColumn = Expression<Double>("price")
    
    init(db: Connection) {
        do {
//            try db.run(table.drop(ifExists: true))
            try db.run(table.create() { table in
                table.column(idColumn, primaryKey: .autoincrement)
                table.column(dateColumn)
                table.column(statusColumn)
                table.column(departureIataColumn)
                table.column(departureScheduledColumn)
                table.column(arrivalIataColumn)
                table.column(arrivalScheduledColumn)
                table.column(flightNumberColumn)
                table.column(durationColumn)
                table.column(freeSeatsColumn)
                table.column(priceColumn)
            })
        } catch {
            print("Error initializing table: \(error)")
            return
        }
        
        do {
            try loadFromCsv(db: db)
        } catch {
            print("Error loading from CSV: \(error)")
        }
    }
    
    func loadFromCsv(db: Connection) throws {
        print("Loading from CSV.")
        let csvFileURL = "Resources/CsvData/flights.csv"

        let data = try String(contentsOfFile: csvFileURL)
        let rows = data.components(separatedBy: "\n").dropFirst()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        for row in rows {
            let columns = row.components(separatedBy: ",")
            if columns.count >= 7 {
                let date = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let status = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let departureIata = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let departureScheduled = dateFormatter.date(
                    from:columns[3].trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                ) ?? Date(timeIntervalSince1970: 0)
                let arrivalIata = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                let arrivalScheduled = dateFormatter.date(
                    from: columns[5].trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                ) ?? Date(timeIntervalSince1970: 0)
                let flightNumber = Int(columns[6].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                let duration = arrivalScheduled.timeIntervalSince(departureScheduled) / 3600
                let freeSeats = Int.random(in: 10..<301)
                var price = duration * Double(300 - freeSeats) + Double(Int.random(in: -100..<100))
                if price <= 100 {
                    price = 100
                }

                let insert = table.insert(
                    dateColumn <- date,
                    statusColumn <- status,
                    departureIataColumn <- departureIata,
                    departureScheduledColumn <- departureScheduled,
                    arrivalIataColumn <- arrivalIata,
                    arrivalScheduledColumn <- arrivalScheduled,
                    flightNumberColumn <- flightNumber,
                    durationColumn <- duration,
                    freeSeatsColumn <- freeSeats,
                    priceColumn <- price
                )
                try db.run(insert)
            }
        }
    }
  
}

struct UsersTable {
    let table = Table("users")
    
    let emailColumn = Expression<String>("login")
    let passwordColumn = Expression<String>("password")
    let fullNameColumn = Expression<String>("fullName")
    let passportNumberColumn = Expression<String>("passportNumber")
    let phoneNumberColumn = Expression<Int>("phoneNumber")
    let genderColumn = Expression<String>("gender")
    
    init(db: Connection) {
        do {
            try db.run(table.create(ifNotExists: true) { table in
                table.column(emailColumn, primaryKey: true)
                table.column(passwordColumn)
                table.column(fullNameColumn)
                table.column(passportNumberColumn)
                table.column(phoneNumberColumn)
                table.column(genderColumn)
            })
        } catch {
            print("Error initializing table: \(error)")
            return
        }
    }
}

struct TicketsTable {
    let table = Table("users")
    
    let loginColumn = Expression<String>("login")
    let flightIdColumn = Expression<Int>("flightId")
    
    init(db: Connection) {
        do {
            try db.run(table.create(ifNotExists: true) { table in
                table.column(loginColumn)
                table.column(flightIdColumn)
            })
        } catch {
            print("Error initializing table: \(error)")
            return
        }
    }
}
