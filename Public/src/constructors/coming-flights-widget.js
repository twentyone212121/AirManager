document.querySelector("#coming-flights-widget").innerHTML = `
    <table id="coming-flights">
        <thead>
            <tr>
                <th colspan="3">Upcoming flights:</th>
            </tr>
            <tr>
                <th>Time</th>
                <th>Number</th>
                <th>From-To</th>
            </tr>
        </thead>
        <tbody></tbody>
    </table>
`

for (let i = 0; i < 50; i++) {
    document.querySelector("#coming-flights tbody").innerHTML += `<tr>
        <td>13:50</td>
        <td>GC1234</td>
        <td>Kyiv - Amsterdam</td>
        </tr>`
}