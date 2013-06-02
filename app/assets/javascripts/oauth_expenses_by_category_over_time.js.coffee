# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"

prettyFriendName = (f) -> "#{f.first_name} #{f.last_name}"

options = 
    chartType: 'LineChart'

    optionsMainChart:
        legend:
            textStyle: 
                fontName: 'Lato, Lucida Grande'
        hAxis:
            textStyle: 
                fontName: 'Lato, Lucida Grande'
            slantedText: true
        vAxis:
            textStyle:
                fontName: 'Lato, Lucida Grande'
            format: '$###,###.##'
    
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
    categories = d.categories
    expenses_records = d.expenses
    rows = []
    for category in categories
        cols.push({id: category, label: category, type:'number'})
    for expenses_record in expenses_records
        console.debug(expenses_record)
        date = new Date(expenses_record.date)
        rows.push({
                        c:  [
                                {
                                    v: date, 
                                    f: prettyTime(date)
                                }
                            ].concat(expenses_record.expenses.map((e) -> {
                                                                            v: e,
                                                                            f: "$#{e.toFixed(2)}"
                                                                         }))
                  })

    console.debug('I will create a scrolled chart...')
    console.debug($('#main-chart')[0])
    console.debug('g')
    createScrolledChart({cols: cols, rows: rows}, options)










































###
                                {   
                                    v: Number(e.total), 
                                    f: "#{e.description}\nCost: $#{e.expense.toFixed(2)}\nTotal: $#{e.total.toFixed(2)}"
                                }
###