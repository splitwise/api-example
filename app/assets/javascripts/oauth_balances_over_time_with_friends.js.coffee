# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"

prettyFriendName = (f) -> "#{f.first_name} #{f.last_name}"

options = 
    chartType: 'AreaChart'

    cols: [{id: 'date', type: 'date'}],
    
    url: '/user/get_balances_over_time_with_friends'
    
    processData: (d) ->
        console.debug(d)
        friends = d.friends
        balanceses = d.balances
        rows = []
        for friend in friends
            options.cols.push({id: friend.id, label: prettyFriendName(friend), type:'number'})
        console.debug(balanceses)
        for [strDate, balances] in balanceses
            console.debug(balances)
            date = new Date(strDate)
            rows.push({
                            c:  [
                                    {
                                        v: date, 
                                        f: prettyTime(date)
                                    }
                                ].concat(balances.map((b) -> {v: b or 0}))
                      })
        console.debug(rows)
        return rows
    
    optionsMainChart:
        hAxis:
            textStyle: 
                fontName: 'Lucida Grande'
        vAxis:
            textStyle:
                fontName: 'Lucida Grande'
    
    optionsScrollChart:
        backgroundColor: '#F5F5F5'
        chartArea:
            width: '100%'
            height: '100%'
        hAxis:
            textPosition: 'none'
        vAxis:
            textPosition: 'none'

createScrolledChart(options)