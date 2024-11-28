class App.GlobalSearch extends App.Controller
  ajaxCount: 0
  constructor: ->
    super
    @searchResultCache = {}
    @lastParams = undefined
    @apiPath = App.Config.get('api_path')
    @ajaxId = "search-#{Math.floor( Math.random() * 999999 )}"

  search: (params) =>
    query = params.query

    cacheKey = @searchResultCacheKey(query, params)

    # use cache for search result
    currentTime = new Date
    if !params.force && @searchResultCache[cacheKey] && @searchResultCache[cacheKey].time > currentTime.setSeconds(currentTime.getSeconds() - 20)
      if @ajaxRequestId
        App.Ajax.abort(@ajaxRequestId)
      @ajaxStart(params)
      @renderTry(@searchResultCache[cacheKey].result, query, params)
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
        id:   @ajaxId
        type: 'GET'
        url: "#{@apiPath}/search"
        data:
          query: query
          by_object: true
          objects: params.object
          limit: @limit || 10
          offset: params.offset
          order_by: params.orderDirection
          sort_by: params.orderBy
        processData: true
        success: (data, status, xhr) =>
          @clearDelay('global-search-ajax-longer-as-expected')
          App.Collection.loadAssets(data.assets)

          userProfileAccess         = @permissionCheck(App.Config.get('user/profile/:user_id', 'Routes').requiredPermission)
          organizationProfileAccess = @permissionCheck(App.Config.get('organization/profile/:organization_id', 'Routes').requiredPermission)

          result = {}
          for klassName, metadata of data.result
            # user and organization are allowed via API but should not show # up for customers because there are no profile pages for customers
            continue if klassName is 'User' && !userProfileAccess
            continue if klassName is 'Organization' && !organizationProfileAccess

            klass = App[klassName]

            if !klass.find
              App.Log.error('_globalSearchSingleton', "No such model App.#{klassName}")
              continue

            item_objects = []

            for item_id in metadata.object_ids
              item_object = klass.find(item_id)

              if !item_object.searchResultAttributes
                App.Log.error('_globalSearchSingleton', "No such model #{klassName.toLocaleLowerCase()}.searchResultAttributes()")
                continue

              item_objects.push(item_object.searchResultAttributes())

            result[klassName] = { items: item_objects, total_count: metadata.total_count }

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
    cacheKey = @searchResultCacheKey(query, params)

    if query
      if _.isEmpty(result)
        if params.callbackNoMatch
          params.callbackNoMatch()
      else
        if params.callbackMatch
          params.callbackMatch()

      # if result hasn't changed, do not rerender
      if !params.force && @lastParams is params && @searchResultCache[cacheKey]
        diff = difference(@searchResultCache[cacheKey].result, result)
        if _.isEmpty(diff)
          return

      @lastParams = params

      # cache search result
      @searchResultCache[cacheKey] =
        result: result
        time: new Date

    @render(result, params)

  searchResultCacheKey: (query, params) ->
    "#{query}-#{params.object}-#{params.offset}-#{params.orderDirection}-#{params.orderBy}"

  close: =>
    @lastParams = undefined
