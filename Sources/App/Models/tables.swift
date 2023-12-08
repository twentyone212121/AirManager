//
//  File.swift
//  
//
//  Created by Denis Kyslytsyn on 09.12.2023.
//

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
            try db.run(table.drop(ifExists: true))
            try db.run(table.create(ifNotExists: true) { table in
                table.column(nameColumn)
                table.column(iso2Column, unique: true, check: iso2Column.length == 2)
                table.column(iso3Column, unique: true, check: iso3Column.length == 3)
                table.column(populationColumn)
                table.column(capitalColumn)
                table.column(continentColumn)
            })
            try loadFromCsv(db: db)
        } catch {
            print("Error initializing table: \(error)")
        }
    }
    
    func loadFromCsv(db: Connection) throws {
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
    let dateColumn = Expression<Date>("date")
    let statusColumn = Expression<String>("status")
    let departureIataColumn = Expression<String>("departureIata")
    let departureScheduledColumn = Expression<Date>("departureScheduled")
    let arrivalIataColumn = Expression<String>("arrivalIata")
    let arrivalScheduledColumn = Expression<Date>("arrivalScheduled")
    let flightNumberColumn = Expression<Int>("flightNumber")
    
    init(db: Connection) {
        do {
            try db.run(table.drop(ifExists: true))
            try db.run(table.create(ifNotExists: true) { table in
                table.column(dateColumn)
                table.column(statusColumn)
                table.column(departureIataColumn)
                table.column(departureScheduledColumn)
                table.column(arrivalIataColumn)
                table.column(arrivalScheduledColumn)
                table.column(flightNumberColumn)
            })
            try loadFromCsv(db: db)
        } catch {
            print("Error initializing table: \(error)")
        }
    }
    
    func loadFromCsv(db: Connection) throws {
        let csvFileURL = "Resources/CsvData/flights.csv"

        let data = try String(contentsOfFile: csvFileURL)
        let rows = data.components(separatedBy: "\n").dropFirst()

        for row in rows {
            let columns = row.components(separatedBy: ",")
            if columns.count >= 7 {
                let date = Date(rfc1123: columns[0].trimmingCharacters(in: .whitespacesAndNewlines))
                let status = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let departureIata = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let departureScheduled = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                let arrivalIata = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                let arrivalScheduled = columns[5].trimmingCharacters(in: .whitespacesAndNewlines)
                let flightNumber = Int(columns[6].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

                let insert = table.insert()
                try db.run(insert)
            }
        }
    }
}

