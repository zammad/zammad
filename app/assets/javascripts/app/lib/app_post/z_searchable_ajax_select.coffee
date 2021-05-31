class App.SearchableAjaxSelect extends App.SearchableSelect
  constructor: ->
    super

    # create cache
    @searchResultCache = {}

  onInput: (event) =>
    super

    # convert requested object
    # e.g. Ticket to ticket or AnotherObject to another_object
    objectString = underscored(@options.attribute.object)

    query = @input.val()

    # create cache key
    cacheKey = "#{objectString}+#{query}"

    # use cache for search result
    if @searchResultCache[cacheKey]
      App.Ajax.abort @options.attribute.id
      @renderResponse @searchResultCache[cacheKey], query
      return

    # add timeout for loader icon
    if !@loaderTimeoutId
      @loaderTimeoutId = setTimeout @showLoader, 1000

    attributes =
      id:   @options.attribute.id
      type: 'GET'
      url:  "#{App.Config.get('api_path')}/search/#{objectString}"
      data:
        query: query
        limit: @options.attribute.limit
      processData: true
      success:     (data, status, xhr) =>
        # cache search result
        @searchResultCache[cacheKey] = data

        @renderResponse(data, query)

    # if delegate is given and provides getAjaxAttributes method, try to extend ajax call
    # this is needed for autocompletion field in KB answer-to-answer linking to submit search context
    if @delegate?.getAjaxAttributes
      attributes = @delegate?.getAjaxAttributes?(@, attributes)

    # start search request and update options
    App.Ajax.request(attributes)

  renderResponse: (data, originalQuery) =>
    # clear timout and remove loader icon
    clearTimeout @loaderTimeoutId
    @loaderTimeoutId = undefined
    @el.removeClass('is-loading')

    # load assets
    App.Collection.loadAssets(data.assets)

    # get options from search result
    options = data
      .result
      .map (elem) =>
        # use search results directly to avoid loading KB assets in Ticket view
        if @useAjaxDetails
          @renderResponseItemAjax(elem, data)
        else
          @renderResponseItem(elem)
      .filter (elem) -> elem?

    # fill template with gathered options
    @optionsList.html @renderOptions options

    # refresh elements
    @refreshElements()

  renderResponseItemAjax: (elem, data) ->
    result = _.find(data.details, (detailElem) -> detailElem.type == elem.type and detailElem.id == elem.id)

    category = undefined
    if result.type is 'KnowledgeBase::Answer::Translation' && result.subtitle
      category = result.subtitle

    if result
      {
        category: category
        name:     result.title
        value:    elem.id
      }

  renderResponseItem: (elem) ->
    object = App[elem.type.replace(/::/g, '')]?.find(elem.id)

    if !object
      return

    name = if object instanceof App.Ticket
             "##{object.number} - #{object.title}"
           else
             object.displayName()

    {
      name:  name
      value: object.id
    }

  showLoader: =>
    @el.addClass('is-loading')
