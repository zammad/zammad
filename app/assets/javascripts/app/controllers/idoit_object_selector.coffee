class App.IdoitObjectSelector extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'i-doit'
  lastSearchTermEmpty: false

  content: ->
    @ajax(
      id:    'idoit-object-selector'
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit"
      data:  JSON.stringify(method: 'cmdb.object_types')
      success: (data, status, xhr) =>
        if data.result is 'failed'
          @contentInline = data.message
          @render()
          return

        result = _.sortBy(data.response.result, 'title')
        @contentInline = $(App.view('integration/idoit_object_selector')())

        @contentInline.find('.js-typeSelect').html(@renderTypeSelector(result))

        @contentInline.on('change', 'input.js-shadow', (e) =>
          params = @formParam(e.target)
          @search(params)
        )
        @contentInline.on('keyup', 'input.js-searchField', (e) =>
          params = @formParam(e.target)
          @search(params)
        )
        @render()
        @$('.js-input').focus()

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @contentInline = 'Unable to load content'
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
      filter.title = "%#{filter.title}%"
    @lastSearchTermEmpty = false
    @ajax(
      id:    'idoit-object-selector'
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit"
      data:  JSON.stringify(method: 'cmdb.objects', filter: filter)
      success: (data, status, xhr) =>
        return if @lastSearchTermEmpty
        @renderResult(data.response.result)

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @contentInline = 'Unable to load content'
        @render()
    )

  renderResult: (items) =>
    table = App.view('integration/idoit_object_result')(
      items: items
    )
    @el.find('.js-result').html(table)

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

