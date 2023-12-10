function readTableValues() {
    let table = document.getElementById("found-flights");
    let tableValues = [];

    for (let i = 1; i < table.rows.length; i++) {
        let cells = table.rows[i].cells;
        let rowValues = [];

        for (let j = 0; j < cells.length; j++) {
            rowValues.push(cells[j].textContent);
        }

        tableValues.push(rowValues);
    }

    return tableValues;
}

function sortByPrice(values) {
    values.sort(function(a, b) {
        let priceA = parseInt(a[4]);
        let priceB = parseInt(b[4]);

        return priceA - priceB;
    });
    return values;
}

function sortByTime(values) {
    values.sort(function(a, b) {
        let durationA = parseFloat(a[3]);
        let durationB = parseFloat(b[3]);

        return durationA - durationB;
    });
    return values;
}

function sortByDeparture(values) {

}

function sortByArrival(values) {

}

let selectElement = document.getElementById("#sort");
selectElement.addEventListener("change", function() {
    let tableValues = readTableValues();
    switch (selectElement.value) {
        case "price":
            let sortedValues = sortByPrice(tableValues);
            console.log(sortedValues);
            break;
        case "time":
            sortByTime(tableValues);
            break;
        case "departure":
            sortByDeparture(tableValues);
            break;
        case "arrival":
            sortByArrival(tableValues);
            break;
        default:
            break;
    }
});