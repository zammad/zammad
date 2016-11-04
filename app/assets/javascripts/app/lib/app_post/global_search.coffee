class App.GlobalSearch
  _instance = undefined

  @execute: (args) ->
    if _instance == undefined
      _instance ?= new _globalSearchSingleton
    _instance.execute(args)

class _globalSearchSingleton extends Spine.Module

  constructor: ->
    @searchResultCache = {}
    @apiPath = App.Config.get('api_path')

  execute: (params) ->
    query     = params.query
    render    = params.render
    limit     = params.limit || 10
    cache_key = query + '_' + limit

    # use cache for search result
    currentTime = new Date
    if @searchResultCache[cache_key] && @searchResultCache[cache_key].time > currentTime.setSeconds(currentTime.getSeconds() - 20)
      render(@searchResultCache[cache_key].result)
      return

    App.Ajax.request(
      id:    'search'
      type:  'GET'
      url:   "#{@apiPath}/search"
      data:
        query: query
        limit: limit
      processData: true,
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

        diff = false
        if @searchResultCache[cache_key]
          diff = difference(@searchResultCache[cache_key].resultRaw, data.result)

        # cache search result
        @searchResultCache[cache_key] =
          result: result
          resultRaw: data.result
          limit: limit
          time: new Date

        # if result hasn't changed, do not rerender
        return if diff isnt false && _.isEmpty(diff)

        render(result)
    )
