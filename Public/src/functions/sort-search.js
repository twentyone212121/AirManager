function getThIndexById(tableId, thId) {
    let table = document.getElementById(tableId);
    let headers = table.getElementsByTagName('th');

    for (var i = 0; i < headers.length; i++) {
        if (headers[i].id === thId) {
            return i;
        }
    }
    return -1;
}

function convertToMinutes(timeString) {
    let timeParts = timeString.split(":");
    let hours = parseInt(timeParts[0], 10);
    let minutes = parseInt(timeParts[1], 10);
    return hours * 60 + minutes;
}

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

function displayTable(tableValues) {
    let table = document.getElementById("found-flights");
    let tbody = table.querySelector('tbody');

    while (tbody.firstChild) {
        tbody.removeChild(tbody.firstChild);
    }

    // Add rows based on sorted values
    for (let i = 0; i < tableValues.length; i++) {
        let row = tbody.insertRow(i);

        for (let j = 0; j < tableValues[i].length; j++) {
            let cell = row.insertCell(j);
            cell.textContent = tableValues[i][j];
        }
    }
}

function sortByPrice(values, order) {
    values.sort(function(a, b) {
        let index = getThIndexById('found-flights', 'price')
        let priceA = parseInt(a[index]);
        let priceB = parseInt(b[index]);

        return order * (priceA - priceB);
    });
    return values;
}

function sortByTime(values, order) {
    values.sort(function(a, b) {
        let index = getThIndexById('found-flights', 'duration')
        let durationA = parseFloat(a[index]);
        let durationB = parseFloat(b[index]);

        return order * (durationA - durationB);
    });
    return values;
}

function sortByDeparture(values, order) {
    values.sort(function(a, b) {
        let index = getThIndexById('found-flights', 'departure')
        let dateA = convertToMinutes(a[index]);
        let dateB = convertToMinutes(b[index]);

        return order * (dateA - dateB);
    });
    return values;
}

function sortByArrival(values, order) {
    values.sort(function(a, b) {
        let index = getThIndexById('found-flights', 'arrival')
        let dateA = convertToMinutes(a[index]);
        let dateB = convertToMinutes(b[index]);

        return order * (dateA - dateB);
    });
    return values;
}

let resultElement = document.getElementById("result");
resultElement.addEventListener("change", function() {
    const selectElement = document.getElementById("sort");
    const sortOrder = document.getElementById("sort-order").checked ? 1 : -1;
    let tableValues = readTableValues();
    let sortedValues;
    switch (selectElement.value) {
        case "price":
            sortedValues = sortByPrice(tableValues, sortOrder);
            displayTable(sortedValues);
            break;
        case "time":
            sortedValues = sortByTime(tableValues, sortOrder);
            displayTable(sortedValues);
            break;
        case "departure":
            sortedValues = sortByDeparture(tableValues, sortOrder);
            displayTable(sortedValues);
            break;
        case "arrival":
            sortedValues = sortByArrival(tableValues, sortOrder);
            displayTable(sortedValues);
            break;
        default:
            break;
    }
});