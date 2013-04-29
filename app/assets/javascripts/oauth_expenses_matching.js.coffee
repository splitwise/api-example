

### I don't use this; it would be identical to oauth_expenses.js.coffee
urlParams = Hash[*window.location.href[window.location.href.indexOf('?') + 1..].split(/&|=/)]

console.log(urlParams)

prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"


options = 
    chartType: 'AreaChart'

    optionsMainChart:
        colors: ['#0088CC']
        legend: 
            position: 'none'
        hAxis:
            textStyle: 
                fontName: 'Lucida Grande'
        vAxis:
            textStyle:
                fontName: 'Lucida Grande'

    optionsScrollChart:
        colors: ['#0088CC']
        backgroundColor: '#F5F5F5'
        chartArea:
            width: '100%'
            height: '100%'
        legend: 
            position: 'none'
        hAxis:
            textPosition: 'none'
        vAxis:
            textPosition: 'none'


cols = [{id: 'date', type: 'date'}, {id: 'balance', type: 'number'}]

this.primeCharts = (data) ->
    rows = data.map((e) -> 
        date = new Date(e.date)
        {c: [{v: date, f: prettyTime(date)}, {v: Number(e.expense)}]}
    )

    $(activateMatchbox)
    createScrolledChart({cols: cols, rows: rows}, options)
###





































    