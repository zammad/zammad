class App.GlobalSearch extends App.Controller
  ajaxCount: 0
  constructor: ->
    super
    @searchResultCache = {}
    @lastQuery = undefined
    @apiPath = App.Config.get('api_path')
    @ajaxId = "search-#{Math.floor( Math.random() * 999999 )}"

  search: (params) =>
    query = params.query

    # use cache for search result
    currentTime = new Date
    if @searchResultCache[query] && @searchResultCache[query].time > currentTime.setSeconds(currentTime.getSeconds() - 20)
      if @ajaxRequestId
        App.Ajax.abort(@ajaxRequestId)
      @ajaxStart(params)
      @renderTry(@searchResultCache[query].result, query, params)
      delayCallback = =>
        @ajaxStop(params)
      @delay(delayCallback, 700)
      return

    delayCallback = =>

      @ajaxStart(params)

      delayCallback = ->
        if params.callbackLongerAsExpected
          params.callbackLongerAsExpected()
      @delay(delayCallback, 10000, 'global-search-ajax-longer-as-expected')

      @ajaxRequestId = App.Ajax.request(
        id:    @ajaxId
        type:  'GET'
        url:   "#{@apiPath}/search"
        data:
          query: query
          limit: @limit || 10
        processData: true
        success: (data, status, xhr) =>
          @clearDelay('global-search-ajax-longer-as-expected')
          App.Collection.loadAssets(data.assets)
          result = {}
          for item in data.result
            if App[item.type] && App[item.type].find
              if !result[item.type]
                result[item.type] = []
              item_object = App[item.type].find(item.id)
              if item_object.searchResultAttributes
                item_object_search_attributes = item_object.searchResultAttributes()
                result[item.type].push item_object_search_attributes
              else
                App.Log.error('_globalSearchSingleton', "No such model #{item.type.toLocaleLowerCase()}.searchResultAttributes()")
            else
              App.Log.error('_globalSearchSingleton', "No such model App.#{item.type}")
          @ajaxStop(params)
          @renderTry(result, query, params)
        error: =>
          @clearDelay('global-search-ajax-longer-as-expected')
          @ajaxStop(params)
      )
    @delay(delayCallback, params.delay || 1, 'global-search-ajax')

  ajaxStart: (params) =>
    @ajaxCount++
    if params.callbackStart
      params.callbackStart()

  ajaxStop: (params) =>
    @ajaxCount--
    if @ajaxCount == 0 && params.callbackStop
      params.callbackStop()

  renderTry: (result, query, params) =>

    if query
      if _.isEmpty(result)
        if params.callbackNoMatch
          params.callbackNoMatch()
      else
        if params.callbackMatch
          params.callbackMatch()

      # if result hasn't changed, do not rerender
      if @lastQuery is query && @searchResultCache[query]
        diff = difference(@searchResultCache[query].result, result)
        if _.isEmpty(diff)
          return

      @lastQuery = query

      # cache search result
      @searchResultCache[query] =
        result: result
        time: new Date

    @render(result)

  close: =>
    @lastQuery = undefined
