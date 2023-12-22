function printReportOnFuel(element) {
    let headings = document.getElementById("headings");
    let row = element.closest('tr');
    let printTable = document.createElement('table');
    printTable.innerHTML = headings.outerHTML + row.outerHTML;

    let lastHeading = printTable.lastElementChild.querySelector('th:last-child');
    lastHeading.parentNode.removeChild(lastHeading);

    let lastCell = printTable.lastElementChild.querySelector('td:last-child');
    lastCell.parentNode.removeChild(lastCell);

    return printTable;
}

function printReportOnPassengers(element) {

}

function printReportOnTimeFlights() {
    let table = document.getElementById("report-table");
    let printTable = document.createElement('table');
    printTable.innerHTML = table.outerHTML;
    return printTable;
}

function printReportOnAirportFlights() {
    let table = document.getElementById("report-table");
    let printTable = document.createElement('table');
    printTable.innerHTML = table.outerHTML;
    return printTable;
}

function printReport(element) {
    let style = "<style>";
    style += "body {font-family: Arial, sans-serif;}";
    style += "table {width: 100%; border-collapse: collapse;}";
    style += "th, td {border: 1px solid #ddd; padding: 8px; text-align: left;}";
    style += "th {background-color: #f2f2f2;}";
    style += ".date {display: block; margin-top: 20px;}"
    style += "</style>";

    let reportHeading, printTable;

    switch (element.id) {
        case "passengers":
            let number = 200;
            reportHeading = `Passengers on flight ${number}`;
            printTable = printReportOnPassengers(element);
            break;
        case "time-flights":
            let from = document.getElementById("time-to").innerHTML;
            let to = document.getElementById("time-from").innerHTML;
            reportHeading = `Flights on period from ${from} to ${to}`;
            printTable = printReportOnTimeFlights();
            break;
        case "airport-flights":
            let airport = document.getElementById("airport-name").innerHTML;
            reportHeading = `Flights from airport ${airport}`;
            printTable = printReportOnAirportFlights();
            break;
        case "fuel-usage":
            let flight = document.querySelector(".flight-number").innerHTML;
            reportHeading = `Fuel usage of flight ${flight}`;
            printTable = printReportOnFuel(element);
            break;
    }

    let win = window.open('', '', 'height=900,width=700');
    win.document.write(style);
    win.document.write('<h1>AirManager</h1>');
    win.document.write(`<h2>${reportHeading}</h2>`);
    win.document.write(printTable.outerHTML);
    win.document.write(`<span class="date">Generated on ${new Date()}</span>`)
    win.document.close();

    win.print();
}