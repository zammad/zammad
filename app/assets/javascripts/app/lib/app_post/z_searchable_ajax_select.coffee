class App.SearchableAjaxSelect extends App.SearchableSelect

  onInput: (event) =>
    super

    # convert requested object
    # e.g. Ticket to ticket or AnotherObject to another_object
    objectString = underscored(@options.attribute.object)

    # create common accessors
    @apiPath = App.Config.get('api_path')

    # create cache and cache key
    @searchResultCache = @searchResultCache || {}

    @cacheKey = "#{objectString}+#{@query}"

    # use cache for search result
    if @searchResultCache[@cacheKey]
      return @onAjaxResponse( @searchResultCache[@cacheKey] )

    # add timeout for loader icon
    clearTimeout @loaderTimeoutId
    @loaderTimeoutId = setTimeout @showLoader, 1000

    # start search request and update options
    App.Ajax.request(
      id:   @options.attribute.id
      type: 'GET'
      url:  "#{@apiPath}/search/#{objectString}"
      data:
        query: @query
        limit: @options.attribute.limit
      processData: true
      success:     @onAjaxResponse
    )

  onAjaxResponse: (data, status, xhr) =>

    # clear timout and remove loader icon
    clearTimeout @loaderTimeoutId
    @el.removeClass('is-loading')

    # cache search result
    @searchResultCache[@cacheKey] = data

    # load assets
    App.Collection.loadAssets(data.assets)

    # get options from search result
    options = []
    for object in data.result
      if object.type is 'Ticket'
        ticket = App.Ticket.find(object.id)
        data =
          name:  "##{ticket.number} - #{ticket.title}"
          value: ticket.id
        options.push data
      else if object.type is 'User'
        user = App.User.find( object.id )
        data =
          name:  "#{user.displayName()}"
          value: user.id
        options.push data
      else if object.type is 'Organization'
        organization = App.Organization.find(object.id)
        data =
          name:  "#{organization.displayName()}"
          value: organization.id
        options.push data

    # fill template with gathered options
    @optionsList.html @renderOptions options

    # refresh elements
    @refreshElements()

    # execute filter
    @filterByQuery @query

  showLoader: =>
    @el.addClass('is-loading')
