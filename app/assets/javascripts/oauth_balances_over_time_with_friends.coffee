

prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"

prettyFriendName = (f) -> "#{f.first_name} #{f.last_name}"

options = 
    chartType: 'AreaChart'

    optionsMainChart:
        hAxis:
            textStyle: 
                fontName: 'Lato, Lucida Grande'
        vAxis:
            textStyle:
                fontName: 'Lato, Lucida Grande'
    
    optionsScrollChart:
        backgroundColor: '#F5F5F5'
        chartArea:
            width: '100%'
            height: '100%'
        hAxis:
            textPosition: 'none'
        vAxis:
            textPosition: 'none'


cols = [{id: 'date', type: 'date'}]

this.primeCharts = (d) ->
    console.debug(d)
    friends = d.friends
    balance_records = d.balances
    rows = []
    for friend in friends
        cols.push({id: friend.id, label: prettyFriendName(friend), type:'number'})
    console.debug(balance_records)
    for balance_record in balance_records
        console.debug(balance_record)
        date = new Date(balance_record.date)
        rows.push({
                        c:  [
                                {
                                    v: date, 
                                    f: prettyTime(date)
                                }
                            ].concat(balance_record.balances.map((b) -> {v: b or 0}))
                  })
    console.debug(cols)
    console.debug(rows)

    createScrolledChart({cols: cols, rows: rows}, options)