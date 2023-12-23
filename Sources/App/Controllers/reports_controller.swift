import Vapor

final class ReportsController: RouteCollection {
    func boot(routes: RoutesBuilder) {
        let reports_routes = routes.grouped("reports")
        reports_routes.get("fuelUsage", use: fuelUsageHandler)
        reports_routes.get("airportFlights", use: airportFlightsHandler)
        reports_routes.get("flightsBetween", use: flightsBetweenHandler)
        reports_routes.get("passengersSearch", use: passengersSearchHandler)
        reports_routes.get("passengers", use: passengersHandler)
    }
    
    func fuelUsageHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard let number: Int = req.query["number"] else {
            throw Abort(.expectationFailed)
        }
        let fuelUsage = req.application.databaseManager.getFuelUsage(flightNumber: number)
        return req.view.render(
            "DataTemplates/ManagerActions/ReportInterfaces/fuelUsageReportTable",
            ["fuelUsageRows": fuelUsage]
        )
    }
    
    func airportFlightsHandler(_ req: Request) throws -> EventLoopFuture<View> {
        struct AirportFlightsParams: Content  {
            let flights: [Flight]
            let airport: String
        }

        guard let airport: String = req.query["airport"] else {
            throw Abort(.expectationFailed)
        }
        let flights = req.application.databaseManager.getFlightsFromAirport(departureIata: airport)
        return req.view.render(
            "DataTemplates/ManagerActions/ReportInterfaces/airportFlightsReportTable",
            AirportFlightsParams(flights: flights, airport: airport)
        )
    }
    
    func flightsBetweenHandler(_ req: Request) throws -> EventLoopFuture<View> {
        struct FlightsBetweenData: Content {
            let flights: [Flight]
            let timeFrom: Date
            let timeTo: Date
        }
        
        guard let fromDate: String = req.query["fromDate"],
                let toDate: String = req.query["toDate"] else {
            throw Abort(.badRequest)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        guard let fromDate = dateFormatter.date(from: fromDate),
              let toDate = dateFormatter.date(from: toDate) else {
            throw Abort(.expectationFailed)
        }
        
        let flights = req.application.databaseManager.getFlightsBetween(from: fromDate, to: toDate)
        return req.view.render(
            "DataTemplates/ManagerActions/ReportInterfaces/timeFlightsReportTable",
            FlightsBetweenData(flights: flights, timeFrom: fromDate, timeTo: toDate)
        )
    }
    
    func passengersSearchHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard let number: Int = req.query["number"] else {
            throw Abort(.badRequest)
        }
        let flights = req.application.databaseManager.getFlights(number: number)
        return req.view.render(
            "DataTemplates/ManagerActions/ReportInterfaces/passengersReportSearchTable",
            ["flights": flights]
        )
    }
    
    func passengersHandler(_ req: Request) throws -> EventLoopFuture<View> {
        struct PassengersInfo: Content {
            let flight: Flight
            let passengers: [User]
        }
        guard let flightId: Int = req.query["flightId"] else {
            throw Abort(.badRequest)
        }
        guard let flight = req.application.databaseManager.getFlight(id: flightId) else {
            throw Abort(.expectationFailed)
        }
        let passengers = req.application.databaseManager.getUsers(by: flightId)
        return req.view.render(
            "DataTemplates/ManagerActions/ReportInterfaces/passengersReportTable",
            PassengersInfo(flight: flight, passengers: passengers)
        )
    }
}
