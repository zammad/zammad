class App.IdoitUpObjectSelector extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('i-doit up')
  lastSearchTermEmpty: false
  currentPage: 0
  pageSize: 25

  content: ->
    @ajax(
      id:    'idoit-up-object-selector'
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit_up"
      data:  JSON.stringify(method: 'cmdb.object_types')
      success: (data, status, xhr) =>
        if data.result is 'failed'
          @contentInline = data.message
          @render()
          return

        result = _.sortBy(data.response.result, 'title')
        @contentInline = $(App.view('integration/idoit_up_object_selector')())

        @contentInline.find('.js-typeSelect').html(@renderTypeSelector(result))

        @contentInline.on('change', 'input.js-shadow', (e) =>
          params = @formParam(e.target)
          @currentPage = 0
          @lastFilter = params
          @search(params)
        )
        @contentInline.on('keyup', 'input.js-searchField', (e) =>
          params = @formParam(e.target)
          @currentPage = 0
          @lastFilter = params
          @search(params)
        )
        @render()
        @$('.js-input').trigger('focus')

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @contentInline = __('Content could not be loaded.')
        @render()
    )
    ''

  search: (filter) =>
    if _.isEmpty(filter.type) && _.isEmpty(filter.title)
      @lastSearchTermEmpty = true
      @renderResult()
      return
    if _.isEmpty(filter.type)
      delete filter.type
    if _.isEmpty(filter.title)
      delete filter.title
    else
      filter.title = "%#{filter.title}%" if filter.title.indexOf('%') is -1
    @lastSearchTermEmpty = false
    @ajax(
      id:    'idoit-up-object-selector'
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit_up"
      data:  JSON.stringify(
        method: 'cmdb.objects'
        filter: filter
        limit:  @pageSize
        offset: @currentPage * @pageSize
      )
      success: (data, status, xhr) =>
        return if @lastSearchTermEmpty
        items = data.response?.result || []
        @renderResult(items)

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @contentInline = __('Content could not be loaded.')
        @render()
    )

  renderResult: (items) =>
    table = App.view('integration/idoit_up_object_result')(
      items:       items
      currentPage: @currentPage
      pageSize:    @pageSize
    )
    @el.find('.js-result').html(table)

    @el.find('.js-prevPage').off('click').on('click', (e) =>
      e.preventDefault()
      return if @currentPage <= 0
      @currentPage -= 1
      @search(@lastFilter) if @lastFilter
    )
    @el.find('.js-nextPage').off('click').on('click', (e) =>
      e.preventDefault()
      @currentPage += 1
      @search(@lastFilter) if @lastFilter
    )

  renderTypeSelector: (result) ->
    options = {}
    for item in result
      options[item.id] = item.title
    return App.UiElement.searchable_select.render(
      name: 'type'
      multiple: false
      limit: 100
      null: false
      nulloption: false
      options: options
    )

  onSubmit: (e) =>
    form = @el.find('.js-result')
    params = @formParam(form)
    return if _.isEmpty(params.object_id)

    if _.isArray(params.object_id)
      object_ids = params.object_id
    else
      object_ids = [params.object_id]

    @formDisable(form)
    @callback(object_ids, @)
