class Index extends App.ControllerContent
  events:
    'blur input':      'update'
    'click .js-Reset': 'reset'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @title 'Translations'

    @render()
    @load()

  load: =>
    @ajax(
      id:    'translations_admin'
      type:  'GET'
      url:   @apiPath + '/translations/admin/lang/de'
      processData: true
      success: (data, status, xhr) =>
        @render(data)
    )

  render: (data = {}) =>
    @html App.view('translation')(
      list:            data.list
      timestampFormat: data.timestampFormat
      dateFormat:      data.dateFormat
    )
    ui = @
    @$('.js-Item').each( (e) ->
      id = $(this).data('id')
      ui.updateRow(id)
    )

  reset: (e) ->
    e.preventDefault()
    field   = $(e.target).closest('tr').find('.js-Item')
    id      = field.data('id')
    initial = field.data('initial')
    field.val( initial )
    @updateRow(id)
    params =
      id:     id
      target: initial

    @ajax(
      id:          'translations'
      type:        'PUT'
      url:         @apiPath + '/translations/' + id
      data:        JSON.stringify(params)
      processData: false
    )

  update: (e) ->
    e.preventDefault()
    id     = $( e.target ).data('id')
    target = $( e.target ).val()
    @updateRow(id)
    params =
      id:     id
      target: target

    @ajax(
      id:          'translations'
      type:        'PUT'
      url:         @apiPath + '/translations/' + id
      data:        JSON.stringify(params)
      processData: false
    )

  updateRow: (id) =>
    field   = @$("[data-id=#{id}]")
    current = field.val()
    initial = field.data('initial')
    reset   = field.closest('tr').find('.js-Reset')
    if current isnt initial
      reset.show()
      reset.closest('tr').addClass('warning')
    else
      reset.hide()
      reset.closest('tr').removeClass('warning')


App.Config.set( 'Translation', { prio: 1800, parent: '#system', name: 'Translations', target: '#system/translation', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
