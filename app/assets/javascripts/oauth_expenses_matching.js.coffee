
urlParams = {}
for [k, v] in window.location.href[(window.location.href.indexOf('?') + 1)..].split(/&/).map((param) -> param.split(/\=/))
    urlParams[k] = v

console.debug(urlParams)

compare = (a, b) ->
    if a < b
        return -1
    else if a > b
        return 1
    else
        return 0

pick = (obj, keys) ->
    result = {}
    for key in keys
        result[key] = obj[key]
    return result

strRepeat = (n, str) ->
    if n is 0
        ''
    else 
        str + strRepeat(n - 1, str)

prettyTime = (t) -> "#{t.toLocaleTimeString()} #{t.getMonth()+1}/#{t.getDate()}"


options = 
    chartType: 'AreaChart'

    optionsMainChart:
        legend:
            textStyle: 
                fontName: 'Lato, Lucida Grande'
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
        legend: 
            position: 'none'
        hAxis:
            textPosition: 'none'
        vAxis:
            textPosition: 'none'


cols = [{id: 'date', type: 'date'}, {id: 'balance', type: 'number'}]
rows = undefined

data2Rows = (data) ->
    return data.map((e) -> 
            date = new Date(e.date)
            {c: 
                [
                    {v: date, f: prettyTime(date)}, 
                    {   
                        v: Number(e.total), 
                        f: "#{e.description}\nCost: $#{e.expense.toFixed(2)}\nTotal: $#{e.total.toFixed(2)}"
                    }
                ]
            }
    )

searches = [] # of the form {search: String, rows: [{date: String, expense: Number, total: Number, description: String}]}

aggregatedCols = () -> 
    result = [{label: 'date', type: 'date'}].concat(searches.map((s) -> {label: s.search, type: 'number'}))
    console.debug('Aggregated cols:')
    console.debug(result)
    return result

aggregatedRows = () -> # of the form [{date: String, expenses: [{expense: Number, total: Number, description: String}]}]
    console.debug('aggregatedRows: searches:')
    console.debug(searches)

    expenseRecords = {}
    for search, i in searches
        for expense in search.rows
            expenseRecords[expense.date] ?= []
            expenseRecords[expense.date][i] = pick(expense, ['expense', 'total', 'description'])

    console.debug('aggregatedRows: Object.keys:')
    console.debug(Object.keys(expenseRecords).sort())
    console.debug('aggregatedRows: expenseRecords:')
    console.debug(expenseRecords)

    result = []
    Object.keys(expenseRecords).sort().forEach((date, i, dates) -> # sort by date
        
        console.debug('here')
        console.debug(dates)
        #I check for vacant cells:
        for j in [0...searches.length]
            if expenseRecords[date][j] is undefined
                if i is 0
                    console.debug("I add no expense.")
                    expenseRecords[date][j] = {
                        expense: 0, 
                        total: 0, 
                        description: '(No expense)'
                    }
                else
                    console.debug({i: i, j: j, ds: dates[i - 1], er: expenseRecords[dates[i - 1]]})
                    console.debug(expenseRecords[dates[i - 1]][j])
                    expenseRecords[date][j] = {   
                        expense: 0, 
                        total: expenseRecords[dates[i - 1]][j].total
                        description: '(No expense)'
                    }

        result.push(
                    {
                        date: date
                        expenses: expenseRecords[date]
                    }
                   )

    )

    console.debug('Aggregated rows:')
    console.debug(result)
    return result


chartData = () -> 
    console.debug('Searches: ')
    console.debug(searches)
    rows = aggregatedRows().map((r) -> 
                                    date = new Date(r.date)
                                    {c: 
                                        [
                                            {v: date, f: prettyTime(date)}, 
                                        ].concat(r.expenses.map((e) ->
                                            return {   
                                                v: Number(e.total), 
                                                f: "#{e.description}\nCost: $#{e.expense.toFixed(2)}\nTotal: $#{e.total.toFixed(2)}"
                                            }
                                        ))
                                    }
    )
    cols = aggregatedCols()
    return {cols: cols, rows: rows}



elem = {}

$(() ->
    elem.prototypeOfSearchStackItem = $($('.search-stack-item')[0]).clone() #jQuery should find only one search-stack-item.
)

this.primeCharts = (data) ->
    console.debug('data: ')
    console.debug(data)
    searches.push({search: urlParams.query, rows: data})
    console.debug('searches: ')
    console.debug(searches)

    createScrolledChart(chartData(), options)

console.debug(this.primeCharts)

chartLoading = (() ->
    interval = undefined

    return {
        start: () -> 
            count = 0
            interval = setInterval((() -> 
                $('#loading-film-message').html('Loading' + strRepeat(count % 4, ' .'))
                count += 1
            ), 300)
            $('#loading-film').addClass('show')
        stop: () -> 
            $('#loading-film').removeClass('show')
            clearInterval(interval)
            $('#loading-film-message').html('Loading')
    }

    )()

SearchStackItem = (search) ->
    console.debug('search: ' + search)
    result = elem.prototypeOfSearchStackItem.clone()
    result.find('.search-name').html(search)
    result.find('.delete-search').click(() -> slideOutSearchStackItem(result))
    console.debug(result)
    return result

addSearchedExpenses = () ->
    search = $('#search-stack .matchbox .input').val()
    $('#search-stack .matchbox .input').val('')
    console.debug('search: ' + search)
    chartLoading.start()
    slideInSearchStackItem(SearchStackItem(search))
    $.ajax({url: "/user/get_expenses_matching?query=#{search}"}).done((data) ->
        searches.push({search: search, rows: JSON.parse(data)})
        $('#main-chart').empty()
        $('#scroll-chart').empty()
        createScrolledChart(chartData(), options)
        chartLoading.stop()
    )

$(() ->
    first = $('.search-stack-item:first-child')
    first.find('.search-name').html(urlParams.query)
    sliding.searchItemHeight = $('.search-stack-item').outerHeight()
    $('.search-stack-item:first-child').children('.delete-search').click(() -> slideOutSearchStackItem(this))
    $('#search-stack .matchbox .submit').click(addSearchedExpenses)
    $('#search-stack .matchbox .input').keypress((event) ->
        if event.which is 13
            event.preventDefault()
            addSearchedExpenses()
    )
)

###
$(() ->
    $('.submit').click(() ->
        newItem = $("<div class='search-stack-item'>Name</div>")
        newItem.click(() -> slideOutSearchStackItem(this))
        slideInSearchStackItem(newItem)
    )
)
###




#Sliding: 
sliding = 
    insertDuration: 600
    removeDuration: 600
    searchItemHeight: undefined
    framesPerHeight: 2

lastItemHeightFunc = (t) -> sliding.searchItemHeight * t


slideInSearchStackItem = (newItem) ->
    lastItem = $('.search-stack-item:last-child')
    newItemInner = newItem.children('.search-stack-item-content')
    
    newItem.css('position', 'absolute')
    newItem.css('z-index', '0')
    newItemInner.css('display', 'none')
    console.log($('#search-stack').offset())
    if not $('.search-stack-item:nth-last-child(2)')[0]
        newItem.css('top', $('#search-stack').offset().top + 'px')
    newItem.insertBefore($('.search-stack-item:last-child'))

    afterFadeIn = () ->
        clearInterval(moveLastItem)
        lastItem.css('margin-top', 0)
        newItem.css('position', 'static')
        newItem.css('z-index', '1')
   
    moveLastItem = setInterval((() -> 
        start = new Date()
        return () -> 
            lastItem.css('margin-top', 
                         lastItemHeightFunc((new Date() - start) / sliding.insertDuration))
    )(), sliding.insertDuration / sliding.searchItemHeight / sliding.framesPerHeight)

    newItemInner.fadeIn(sliding.insertDuration, afterFadeIn)


slideOutSearchStackItem = (item) ->
    item = $(item)
    item.off('click')

    next = item.next()

    next.css('margin-top', sliding.searchItemHeight)
    item.css('position', 'absolute')
    item.css('z-index', '0')
    if not $('.search-stack-item:nth-last-child(3)')[0] 
        item.css('top', $('#search-stack').offset().top + 'px')
        console.log('offset: ' + ($('#search-stack').offset().top + 'px'))
    
    afterFadeOut = () -> 
        clearInterval(nextTimeout)
        next.css('margin-top', 0)
        item.remove()

    item.children('.search-stack-item-content').fadeOut(sliding.removeDuration, afterFadeOut)

    nextTimeout = setInterval((() ->
        start = new Date()
        return () -> 
            now = new Date()
            next.css('margin-top', 
                     lastItemHeightFunc(1 - (now - start) / sliding.removeDuration))
    )(), sliding.removeDuration / sliding.searchItemHeight / sliding.framesPerHeight)







































