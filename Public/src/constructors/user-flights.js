for (let i = 0; i < 3; i++) {
    document.querySelector("#user-flights-list tbody").innerHTML += `<tr>
        <td>Feb 23, 2022</td>
        <td>14:50 - 13:11 (+1)</td>
        <td>FX98321</td>
        <td>Toronto - Amsterdam</td>
        <td><a href="" class="table-button">Print the ticket</a></td>
        </tr>`
}

for (let i = 0; i < 3; i++) {
    document.querySelector("#user-previous-flights-list tbody").innerHTML += `<tr>
        <td>Feb 23, 2022</td>
        <td>14:50 - 13:11 (+1)</td>
        <td>FX98321</td>
        <td>Toronto - Amsterdam</td>
        </tr>`
}