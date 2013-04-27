
urlParams = Hash[*window.location.href[window.location.href.indexOf('?') + 1..].split(/&|=/)]

console.log(urlParams)

prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"


options = 
    chartType: 'AreaChart'

    cols: [{id: 'date', type: 'date'}, {id: 'balance', type: 'number'}]

    url: "/user/get_expenses_over_time_cumulative?query=#{urlParams['query']}"

    processData: (d) -> d.map((e) -> 
            date = new Date(e.date)
            {c: [{v: date, f: prettyTime(date)}, {v: Number(e.expense)}]}
        )

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

$(activateMatchbox)
createScrolledChart(options)