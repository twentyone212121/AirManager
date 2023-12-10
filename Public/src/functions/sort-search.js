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
        let priceA = parseInt(a[4]);
        let priceB = parseInt(b[4]);

        return order * (priceA - priceB);
    });
    return values;
}

function sortByTime(values, order) {
    values.sort(function(a, b) {
        let durationA = parseFloat(a[3]);
        let durationB = parseFloat(b[3]);

        return order * (durationA - durationB);
    });
    return values;
}

function sortByDeparture(values, order) {
    values.sort(function(a, b) {
        let dateA = a[0];
        let dateB = b[0];

        return order * (dateA - dateB);
    });
    return values;
}

function sortByArrival(values, order) {
    values.sort(function(a, b) {
        let dateA = parseInt(a[1]);
        let dateB = parseInt(b[1]);

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