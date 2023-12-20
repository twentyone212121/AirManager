import Foundation
import SQLite

func parseCSVRow(_ row: String) -> [String] {
    var fields: [String] = []
    
    var currentField = ""
    var insideQuotes = false
    
    for char in row {
        if char == "\"" {
            insideQuotes.toggle()
        } else if char == "," && !insideQuotes {
            fields.append(currentField)
            currentField = ""
        } else {
            currentField.append(char)
        }
    }
    
    // Add the last field
    fields.append(currentField)
    
    return fields
}

func toCurrentDay(_ dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    let currentDayDate = Date().ISO8601Format()
    let centerIndex = currentDayDate.index(currentDayDate.startIndex, offsetBy: 10)
    let currentDateString = currentDayDate[currentDayDate.startIndex..<centerIndex] + dateString[centerIndex...]
    print(currentDateString)
    return dateFormatter.date(from: String(currentDateString))
        ?? Date(timeIntervalSince1970: 0)
}

protocol SqlTable {
}

struct CountriesTable: SqlTable {
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

struct AirportsTable: SqlTable {
    let table = Table("airports")
    
    //"Airport ID","Name","City","Country","IATA","ICAO","Latitude","Longitude","Altitude","Timezone","DST","Tz database time zone","Type","Source"
    let nameColumn = Expression<String>("name")
    let iataColumn = Expression<String>("iata")
    let cityColumn = Expression<String>("city")
    let countryColumn = Expression<String>("country")
    
    init(db: Connection) {
        do {
            try db.run(table.create() { table in
                table.column(nameColumn)
                table.column(iataColumn, primaryKey: true)
                table.column(cityColumn)
                table.column(countryColumn)
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
        print("Loading airports from CSV.")
        let csvFileURL = "Resources/CsvData/airports.csv"

        let data = try String(contentsOfFile: csvFileURL)
        let rows = data.components(separatedBy: "\n").dropFirst()

        for row in rows {
            let columns = parseCSVRow(row)
            if columns.count >= 7 {
                let id = columns[0]
                let name = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let iata = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                if iata == "\\N" {
                    continue
                }
                let city = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let country = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)

                let insert = table.insert(
                    nameColumn <- name,
                    iataColumn <- iata,
                    cityColumn <- city,
                    countryColumn <- country)
                do {
                    try db.run(insert)
                } catch {
                    print("Error inserting into airports \(error)\nid: \(id)\tIATA: \(iata)")
                }
            }
        }
    }
}

struct AirplanesTable: SqlTable {
    let table = Table("airplanes")
    
    let idColumn = Expression<Int>("id")
    let modelColumn = Expression<String>("model")
    let fuelConsumptionColumn = Expression<Int>("fuelConsumption")
    
    var amount: Int = 21
    
    init(db: Connection) {
        do {
            try db.run(table.create() { table in
                table.column(idColumn, primaryKey: .autoincrement)
                table.column(modelColumn)
                table.column(fuelConsumptionColumn)
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
        print("Loading airplanes from CSV.")
        let csvFileURL = "Resources/CsvData/airplanes.csv"

        let data = try String(contentsOfFile: csvFileURL)
        let rows = data.components(separatedBy: "\n").dropFirst()

        for row in rows {
            let columns = parseCSVRow(row)
            if columns.count >= 2 {
                let model = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let fuelConsumption = Int(columns[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

                let insert = table.insert(
                    modelColumn <- model,
                    fuelConsumptionColumn <- fuelConsumption)
                
                try db.run(insert)
            }
        }
    }
}

struct FlightsTable: SqlTable {
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
    let airplaneIdColumn = Expression<Int>("airplaneId")
    
    init(db: Connection, airplanesNum: Int) {
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
                table.column(airplaneIdColumn)
            })
        } catch {
            print("Error initializing table: \(error)")
            return
        }
        
        do {
            try loadFromCsv(db: db, airplanesNum)
        } catch {
            print("Error loading from CSV: \(error)")
        }
    }
    
    func loadFromCsv(db: Connection, _ airplanesNum: Int) throws {
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
                let departureScheduled = toCurrentDay(columns[3].trimmingCharacters(in: .whitespacesAndNewlines))
                let arrivalIata = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                let arrivalScheduled = toCurrentDay(columns[5].trimmingCharacters(in: .whitespacesAndNewlines))
                let flightNumber = Int(columns[6].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                let duration = (arrivalScheduled.timeIntervalSince(departureScheduled) / 36).rounded() / 100
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
                    priceColumn <- price,
                    airplaneIdColumn <- Int.random(in: 1..<(airplanesNum+1))
                )
                try db.run(insert)
            }
        }
    }
  
}

struct UsersTable: SqlTable {
    let table = Table("users")
    
    let emailColumn = Expression<String>("email")
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

struct ManagersTable: SqlTable {
    let table = Table("managers")
    
    let emailColumn = Expression<String>("email")
    let passwordColumn = Expression<String>("password")
    let fullNameColumn = Expression<String>("fullName")
    
    init(db: Connection) {
        do {
            try db.run(table.create(ifNotExists: true) { table in
                table.column(emailColumn, primaryKey: true)
                table.column(passwordColumn)
                table.column(fullNameColumn)
            })
        } catch {
            print("Error initializing table: \(error)")
            return
        }
    }
}

struct TicketsTable: SqlTable {
    let table = Table("tickets")
    
    let emailColumn = Expression<String>("email")
    let flightIdColumn = Expression<Int>("flightId")
    
    init(db: Connection) {
        do {
            try db.run(table.create(ifNotExists: true) { table in
                table.column(emailColumn)
                table.column(flightIdColumn)
            })
        } catch {
            print("Error initializing table: \(error)")
            return
        }
    }
}
