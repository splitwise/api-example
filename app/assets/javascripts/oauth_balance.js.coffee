# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"


options = 
    chartType: 'LineChart'
    
    optionsMainChart:
        colors: ['#0088CC']
        legend: 
            position: 'none'
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
        colors: ['#0088CC']
        backgroundColor: '#F5F5F5'
        chartArea:
            width: '100%'
            height: '100%'
        legend: 
            position: 'none'
            textStyle:
                fontName: 'Lato, Lucida Grande'
        hAxis:
            textPosition: 'none'
        vAxis:
            textPosition: 'none'


cols = [{id: 'date', type: 'date'}, {id: 'balance', type: 'number'}]

this.primeCharts = (data) ->
    console.debug(data)
    rows = data.map((b) -> 
            date = new Date(b.date)
            {c: [{v: date, f: prettyTime(date)}, {v: Number(b.balance), f:"$"+Number(b.balance).toFixed(2)}]}
        ) 

    createScrolledChart({cols: cols, rows: rows}, options)

###
    url: '/user/get_balance_over_time?format=google-charts'
    
    processData: (d) -> d.map(([dateStr, balance]) -> 
            date = new Date(dateStr)
            {c: [{v: date, f: prettyTime(date)}, {v: Number(balance), f:"$"+Number(balance).toFixed(2)}]}
        )
###















































###
createCheckin = (n, callback) -> () ->
    n -= 1
    callback() if n is 0


prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getDate()}/#{t.getMonth()+1}"

scrollLabelDate = (t) -> t.toLocaleDateString()

cols = [{id: 'date', type: 'date'}, {id: 'balance', type: 'number'}]
rows = undefined
optionsMainChart = 
    colors: ['#0088CC']
    legend: 
        position: 'none'
    hAxis:
        textStyle: 
            fontName: 'Lucida Grande'
    vAxis:
        textStyle:
            fontName: 'Lucida Grande'
optionsScrollChart = 
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

dates = {}
spawnDates = () ->
    dates.all = rows.map((r) -> r.c[0].v)
    dates.first = +dates.all[0]
    dates.span = dates.all[dates.all.length - 1] - dates.first

dateOnScroll = (x) -> 
    return new Date(dates.first + dates.span * (x / elem.film.offsetParent().width()))

initScrollChart = () ->
    chart = new google.visualization.AreaChart($('#scroll-chart')[0])
    dataTable = new google.visualization.DataTable({cols: cols, rows: rows})
    google.visualization.events.addListener(chart, 'ready', layerFilm)
    chart.draw(dataTable, optionsScrollChart)
    return chart

initMainChart = () ->
    chart = new google.visualization.AreaChart($('#chart-historical-balance')[0])
    dataTable = new google.visualization.DataTable({cols: cols, rows: rows})
    chart.draw(dataTable, optionsMainChart)
    return chart

redrawMainChart = (startDate, finishDate) ->
    start = Math.max(0, indexOfDateAfter(startDate) - 1)
    finish = indexOfDateAfter(finishDate) + 1
    dataTable = new google.visualization.DataTable({cols: cols, rows: rows.slice(start, finish)})
    elem.mainChart.draw(dataTable, optionsMainChart)

indexOfDateAfter = (date) ->
        for d, i in dates.all                       #optimize this by using a binary search
            if date < d
                return i
        return dates.all.length - 1


drawCharts = createCheckin(3, () ->

    spawnDates()
    elem.scrollChart = initScrollChart()
    elem.mainChart = initMainChart()
    
)



filmHandleLeftDraggable = false
filmHandleRightDraggable = false

elem =
    filmBackdrop: $("<div id='film-backdrop'></div>"),
    film: $("<div id='film'></div>"),
    filmHandleLeft: $("<div class='film-handle left'></div>"),
    filmHandleRight: $("<div class='film-handle right'></div>")
    filmLabelLeft: $("<span class='film-label left'></span>")
    filmLabelRight: $("<span class='film-label right'></span>")
    filmLabelContainerLeft: $("<span class='film-label-container left'></span>")
    filmLabelContainerRight: $("<span class='film-label-container right'></span>")

elem.filmBackdrop.append(elem.film.append(elem.filmHandleLeft.append(elem.filmLabelContainerLeft.append(elem.filmLabelLeft)))
                                  .append(elem.filmHandleRight.append(elem.filmLabelContainerRight.append(elem.filmLabelRight))))

elem.filmHandleLeft.mousedown(() ->
    filmHandleLeftDraggable = true
    elem.filmLabelLeft.css('visibility', 'visible')
)

elem.filmHandleRight.mousedown(() ->
    filmHandleRightDraggable = true
    elem.filmLabelRight.css('visibility', 'visible')
)

$(document).mouseup(() ->
    if filmHandleLeftDraggable or filmHandleRightDraggable
        filmHandleLeftDraggable = false
        filmHandleRightDraggable = false
        elem.filmLabelLeft.css('visibility', 'hidden')
        elem.filmLabelRight.css('visibility', 'hidden')
        redrawMainChart(dateOnScroll(elem.film.position().left),
                        dateOnScroll(elem.film.position().left + elem.film.width()))
)

onMouseMove = (event) ->
    minHandleDistance = 10
    newX = event.pageX - elem.film.offsetParent().offset().left
    if filmHandleLeftDraggable and newX < -minHandleDistance + elem.film.position().left + elem.film.outerWidth() - elem.filmHandleLeft.width() - elem.filmHandleRight.width()
        newX = Math.max(newX, 0)
        elem.film.css('width', elem.film.outerWidth() - newX + parseInt(elem.film.css('left')), 10)
        elem.film.css('left', newX)
        elem.filmLabelLeft.html(scrollLabelDate(dateOnScroll(newX)))
    else if filmHandleRightDraggable and minHandleDistance + elem.film.position().left + elem.filmHandleLeft.width() + elem.filmHandleRight.width() < newX
        newX = Math.min(newX, elem.film.offsetParent().width())
        elem.film.css('width', newX - elem.film.position().left)
        elem.filmLabelRight.html(scrollLabelDate(dateOnScroll(newX)))

$(document).mousemove(onMouseMove)

layerFilm = () ->
    g = $('div#scroll-chart > div > div > svg > g')
    rect = g.children('rect')
    elem.filmBackdrop.offset({top: 0, left: 0})          #I invoke offset with a position because offset seems to work not relative to the document but to the last (possibly positioned) parent. In addition, I supply the position values because e.position() works differently in firefox and webkit.
    elem.filmBackdrop.width(rect.attr('width'))
    elem.filmBackdrop.height(rect.attr('height'))
    $('#scroll-chart').append(elem.filmBackdrop)



google.setOnLoadCallback(drawCharts)
google.load('visualization', '1', {packages: ['corechart']})

$.ajax({url: '/user/get_balance_over_time?format=google-charts'}).done((d) ->

    rows = JSON.parse(d).map(([dateStr, balance]) -> 
        date = new Date(dateStr)
        {c: [{v: date, f: prettyTime(date)}, {v: Number(balance)}]})
    drawCharts()

)

$(document).ready(() -> 

    $('.top-menu-item.balance').addClass('active')
    $('.active a').click(() -> false)
    drawCharts()

)
###