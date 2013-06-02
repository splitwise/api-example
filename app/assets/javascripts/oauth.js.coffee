# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(() -> 
    $('.top-menu-item.matching').click(() ->
        $('#matchbox .input').focus()
    )

    $('#matchbox .submit').click(() ->
        window.location.href = "/user/expenses_matching?query=#{$('#matchbox input').val()}"
    )

    infoboxes = $('.infobox-container')
    $.each($('.top-menu-item'), (i, e) ->
        unless $(e).hasClass('active')
            $(infoboxes[i]).css('left', $(e).position().left)
            $(e).hover((() ->
                $(infoboxes[i]).addClass('show')
            ),(() ->
                $(infoboxes[i]).removeClass('show')
            ))
    )
)

### Example arguments:
chartType = 'AreaChart'

url = '/user/get_balance_over_time?format=google-charts'

cols = [{id: 'date', type: 'date'}, {id: 'balance', type: 'number'}]

processRow = ([dateStr, balance]) -> 
    date = new Date(dateStr)
    {c: [{v: date, f: prettyTime(date)}, {v: Number(balance)}]}


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
###

foo = (->
    i = 0

    return (n) ->
        i += 1
        console.debug(i + ' >>> ' + n)
        console.debug($('#main-chart')[0])
)()

this.createScrolledChart = (data, variable) ->
    debugger
    cols = data.cols
    rows = data.rows
    createCheckin = (n, callback) -> () ->
        n -= 1
        callback() if n is 0

    prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"

    scrollLabelDate = (t) -> t.toLocaleDateString()
    dates = {}
    spawnDates = () ->
        dates.all = rows.map((r) -> r.c[0].v)
        dates.first = +dates.all[0]
        dates.span = dates.all[dates.all.length - 1] - dates.first
    dateOnScroll = (x) -> 
        return new Date(dates.first + dates.span * (x / elem.film.offsetParent().width()))

    createScrollChart = () ->
        chart = new google.visualization[variable.chartType]($('#scroll-chart')[0])
        dataTable = new google.visualization.DataTable({cols: cols, rows: rows})
        google.visualization.events.addListener(chart, 'ready', layerFilm)
        chart.draw(dataTable, variable.optionsScrollChart)
        return chart
    initMainChart = () ->
        chart = new google.visualization[variable.chartType]($('#main-chart')[0])
        return chart
    redrawMainChart = (startDate, finishDate) ->
        start = Math.max(0, indexOfDateAfter(startDate) - 1)
        finish = indexOfDateAfter(finishDate) + 1
        dataTable = new google.visualization.DataTable({cols: cols, rows: rows.slice(start, finish)})
        elem.mainChart.draw(dataTable, variable.optionsMainChart)

    redrawMainChartFromScrolled = () ->
        redrawMainChart(dateOnScroll(elem.film.position().left),
                dateOnScroll(elem.film.position().left + elem.film.width()))
    indexOfDateAfter = (date) ->
            for d, i in dates.all                       #optimize this by using a binary search
                if date < d
                    return i
            return dates.all.length - 1

    drawCharts = createCheckin((if google.visualization then 1 else 2), () ->
        spawnDates()
        elem.scrollChart = createScrollChart()
        elem.mainChart = initMainChart()
        redrawMainChartFromScrolled()
        
    )


    filmHandleLeftDraggable = false
    filmHandleRightDraggable = false
    filmDraggable = false
    filmPressedAt = false
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
    elem.filmHandleLeft.mousedown((event) ->
        event.preventDefault()
        filmHandleLeftDraggable = true
        elem.filmLabelLeft.css('visibility', 'visible')
        $('body').css('cursor', 'col-resize')
        false
    )
    elem.filmHandleRight.mousedown((event) ->
        event.preventDefault()
        filmHandleRightDraggable = true
        elem.filmLabelRight.css('visibility', 'visible')
        $('body').css('cursor', 'col-resize')
        false
    )
    elem.film.mousedown((event) ->
        event.preventDefault()
        filmDraggable = true
        filmPressedAt = event.pageX - $(this).offset().left
    )
    $(document).mouseup(() ->
        if filmHandleLeftDraggable or filmHandleRightDraggable or filmDraggable
            filmHandleLeftDraggable = false
            filmHandleRightDraggable = false
            filmDraggable = false
            elem.filmLabelLeft.css('visibility', 'hidden')
            elem.filmLabelRight.css('visibility', 'hidden')
            $('body').css('cursor', 'default')
            redrawMainChartFromScrolled()
    )
    
    onMouseMove = (event) ->
        minHandleDistance = 10
        newX = event.pageX - elem.film.offsetParent().offset().left
        if filmHandleLeftDraggable and minHandleDistance + elem.filmHandleRight.width() + elem.filmHandleLeft.width() < elem.film.width() - (newX - parseFloat(elem.film.css('left'), 10))
            newX = Math.max(newX, 0)
            elem.film.css('width', elem.film.width() - (newX - parseFloat(elem.film.css('left'), 10)))
            elem.film.css('left', newX)
            console.debug(elem.film.width())
            console.debug(newX)
            console.debug(parseFloat(elem.film.css('left'), 10))
            console.debug(newX - parseFloat(elem.film.css('left'), 10))
            console.debug(elem.film.width() - newX + parseFloat(elem.film.css('left'), 10))
            console.debug(elem.film.width() - (newX - parseFloat(elem.film.css('left'), 10)))
            elem.filmLabelLeft.html(scrollLabelDate(dateOnScroll(newX)))
        else if filmHandleRightDraggable and minHandleDistance + elem.film.position().left + elem.filmHandleLeft.width() + elem.filmHandleRight.width() < newX
            newX = Math.min(newX, elem.film.offsetParent().width())
            elem.film.css('width', newX - elem.film.position().left)
            elem.filmLabelRight.html(scrollLabelDate(dateOnScroll(newX)))
        else if filmDraggable
            newX = newX - filmPressedAt
            newX = Math.min(Math.max(newX, 0), 
                            elem.film.offsetParent().width() - elem.film.width())
            elem.film.css('left', newX)
    $(document).mousemove(onMouseMove)

    layerFilm = () ->
        g = $('div#scroll-chart > div > div > svg > g')
        rect = g.children('rect')
        elem.filmBackdrop.offset({top: 0, left: 0})          #I invoke offset with a position because offset seems to work not relative to the document but to the last (possibly positioned) parent. In addition, I supply the position values because e.position() works differently in firefox and webkit.
        elem.filmBackdrop.width(rect.attr('width'))
        elem.filmBackdrop.height(rect.attr('height'))
        $('#scroll-chart').append(elem.filmBackdrop)

    google.setOnLoadCallback(drawCharts)
    unless google.visualization
        google.load('visualization', '1', {packages: ['corechart']}) unless google.visualization

    ###
    rows = undefined
    $.ajax({url: variable.url}).done((d) ->

        rows = variable.processData(JSON.parse(d))
        drawCharts()

    )
    ###

    $(document).ready(() -> 

        $('.active a').click(() -> 
            event.preventDefault()
        )
        drawCharts()

    )


###
this.activateMatchbox = () ->
    $('.side-menu-item.matching').click(() ->
        $('.side-menu-item.matching #matchbox-container').css('visibility', 'visible')
        false
    )
    $(document).click(() ->
        $('.side-menu-item.matching #matchbox-container').css('visibility', 'hidden')
    )
    $('#matchbox .submit').click(() ->
        window.location.href = "/user/expenses_matching?query=#{$('#matchbox input').val()}"
    )
###