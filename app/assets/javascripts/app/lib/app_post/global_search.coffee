class App.GlobalSearch extends App.Controller
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
      @renderTry(@searchResultCache[query].result, query)
      return

    App.Ajax.request(
      id:    @ajaxId
      type:  'GET'
      url:   "#{@apiPath}/search"
      data:
        query: query
        limit: @limit || 10
      processData: true
      success: (data, status, xhr) =>
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

        @renderTry(result, query)
    )

  renderTry: (result, query) =>

    # if result hasn't changed, do not rerender
    if @lastQuery is query && @searchResultCache[query]
      diff = difference(@searchResultCache[query].result, result)
      if _.isEmpty(diff)
        @render(result, true)
        return

    @lastQuery = query

    # cache search result
    @searchResultCache[query] =
      result: result
      time: new Date

    @render(result)

  close: =>
    @lastQuery = undefined
