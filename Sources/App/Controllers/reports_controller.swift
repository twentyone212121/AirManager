import Vapor

final class ReportsController: RouteCollection {
    func boot(routes: RoutesBuilder) {
        let reports_routes = routes.grouped("reports")
        reports_routes.get("fuelUsage", use: fuelUsageHandler)
        reports_routes.get("airportFlights", use: airportFlightsHandler)
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
        guard let airport: String = req.query["airport"] else {
            throw Abort(.expectationFailed)
        }
        let flights = req.application.databaseManager.getFlightsFromAirport(departureIata: airport)
        return req.view.render(
            "DataTemplates/ManagerActions/ReportInterfaces/airportFlightsReportTable",
            ["flights": flights]
        )
    }
}
