class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @title 'Translations'

    @render()

  render: =>
    @html App.view('translation/index')()
    options = {}
    locales = App.Locale.all()
    for locale in locales
      options[locale.locale] = locale.name
    configure_attributes = [
      { name: 'locale', display: '', tag: 'select', null: false, class: 'input', options: options, default: App.i18n.get()  },
    ]
    load = (params) =>
      new TranslationToDo(
        el:     @$('.js-ToDo')
        locale: params.locale
      )
      new TranslationList(
        el:     @$('.js-List')
        locale: params.locale
      )

    new App.ControllerForm(
      el:        @$('.language')
      model:     { configure_attributes: configure_attributes }
      autofocus: false
      handlers:  [load]
    )

  release: =>
    rerender = ->
      App.Event.trigger('ui:rerender')
    App.Delay.set(rerender, 400)

class TranslationToDo extends App.Controller
  events:
    'click .js-Create':  'create'
    'click .js-TheSame': 'same'

  constructor: ->
    super
    @render()
    @bind(
      'i18n:translation_todo_reload',
      =>
        @render()
    )

  render: =>

    if !App.i18n.notTranslatedFeatureEnabled(@locale)
      @html App.view('translation/english')()
      return

    listNotTranslated = []
    for key, value of App.i18n.getNotTranslated(@locale)
      item = [ '', key, '', '']
      listNotTranslated.push item

    @html App.view('translation/todo')(
      list: listNotTranslated
    )

  create: (e) =>
    e.preventDefault()
    field  = $(e.target).closest('tr').find('.js-Item')
    source = field.data('source')
    target = field.val()

    # remove from not translated list
    $(e.target).closest('tr').remove()

    # local update
    App.i18n.removeNotTranslated( @locale, source )

    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap( source, target, 'string' )

    # remote update
    params =
      locale:         @locale
      source:         source
      target:         target
      target_initial: ''

    @ajax(
      id:          'translations'
      type:        'POST'
      url:         @apiPath + '/translations'
      data:        JSON.stringify(params)
      processData: false
      success: (data, status, xhr) =>
        App.Event.trigger('i18n:translation_list_reload')
    )

  same: (e) =>
    e.preventDefault()
    field  = $(e.target).closest('tr').find('.js-Item')
    source = field.data('source')

    # remove from not translated list
    $(e.target).closest('tr').remove()

    # local update
    App.i18n.removeNotTranslated( @locale, source )

    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap( source, source, 'string' )

    # remote update
    params =
      locale:         @locale
      source:         source
      target:         source
      target_initial: ''

    @ajax(
      id:          'translations'
      type:        'POST'
      url:         @apiPath + '/translations'
      data:        JSON.stringify(params)
      processData: false
      success: (data, status, xhr) =>
        App.Event.trigger('i18n:translation_list_reload')
    )

class TranslationList extends App.Controller
  events:
    'blur .js-translated input':          'update'
    'click .js-translated .js-Reset':     'reset'

  constructor: ->
    super
    @load()
    @bind(
      'i18n:translation_list_reload',
      =>
        @load()
    )

  load: =>
    @ajax(
      id:    'translations_admin'
      type:  'GET'
      url:   @apiPath + "/translations/admin/lang/#{@locale}"
      processData: true
      success: (data, status, xhr) =>
        @render(data)
    )

  render: (data = {}) =>

    #if !App.i18n.notTranslatedFeatureEnabled(@locale)
    #  return

    @strings = []
    @times = []
    for item in data.list
      if item[4] is 'time'
        @times.push item
      else
        @strings.push item

    @html App.view('translation/list')(
      times:   @times
      strings: @strings
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
    source  = field.data('source')
    initial = field.data('initial')
    format  = field.data('format')

    # if it's translated by user it self, delete it
    if !initial || initial is ''

      # locale reset
      $(e.target).closest('tr').remove()

      # update runtime if same language is used
      if App.i18n.get() is @locale
        App.i18n.setMap( source, '', format )

      # remote reset
      params =
        id: id
      @ajax(
        id:          'translations'
        type:        'DELETE'
        url:         @apiPath + '/translations/' + id
        data:        JSON.stringify(params)
        processData: false
        success: =>
          App.i18n.setNotTranslated( @locale, source )
          App.Event.trigger('i18n:translation_todo_reload')
      )
      return


    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap( source, initial, format )

    # locale reset
    field.val( initial )
    @updateRow(id)

    # remote reset
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
    source = $( e.target ).data('source')
    format = $( e.target ).data('format')
    target = $( e.target ).val()

    # local update
    @updateRow(id)

    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap( source, target, format )

    # remote update
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