class Index extends App.ControllerContent
  events:
    'click .js-pushChanges': 'pushChanges'
    'click .js-resetChanges': 'resetChanges'
    'click .js-syncChanges': 'syncChanges'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @title 'Translations', true

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
      @translationToDo = new TranslationToDo(
        el:     @$('.js-ToDo')
        locale: params.locale
      )
      @translationList = new TranslationList(
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
    if @translationToDo.changes() || @translationList.changes()
      App.Delay.set(rerender, 400)

  hideAction: =>
    @el.closest('.content').find('.js-changes').addClass('hidden')

  pushChanges: =>
    locale = @$('[name="locale"]').val()

    @modal = new App.ControllerModal(
      head:      'Pushing own translations...'
      message:   'Pushing own translations to i18n.zammad.com, Thanks for contributing!'
      cancel:    false
      close:     false
      shown:     true
      container: @el.closest('.content')
    )

    @ajax(
      id:          'translations'
      type:        'PUT'
      url:         @apiPath + '/translations/push'
      data:        JSON.stringify(locale: locale)
      processData: false
      success: (data, status, xhr) =>
        @modal.hide()
      error: =>
        @modal.hide()
    )

  resetChanges: =>
    locale = @$('[name="locale"]').val()

    @modal = new App.ControllerModal(
      head:      'Reseting changes...'
      message:   'Reseting changes own translation changes...'
      cancel:    false
      close:     false
      shown:     true
      container: @el.closest('.content')
    )

    @ajax(
      id:          'translations'
      type:        'POST'
      url:         @apiPath + '/translations/reset'
      data:        JSON.stringify(locale: locale)
      processData: false
      success: (data, status, xhr) =>
        @hideAction()
        App.Event.trigger('i18n:translation_todo_reload')
        App.Event.trigger('i18n:translation_list_reload')
        @modal.hide()
      error: =>
        @modal.hide()
    )

  syncChanges: =>
    locale = @$('[name="locale"]').val()

    @modal = new App.ControllerModal(
      head:      'Syncing with latest translations...'
      message:   'Syncing with latest translations!'
      cancel:    false
      close:     false
      shown:     true
      container: @el.closest('.content')
    )

    @ajax(
      id:          'translations'
      type:        'POST'
      url:         @apiPath + '/translations/sync'
      data:        JSON.stringify(locale: locale)
      processData: false
      success: (data, status, xhr) =>
        @hideAction()
        App.Event.trigger('i18n:translation_todo_reload')
        App.Event.trigger('i18n:translation_list_reload')
        @modal.hide()
      error: =>
        @modal.hide()
    )

class TranslationToDo extends App.Controller
  hasChanges: false
  events:
    'click .js-create':  'create'
    'click .js-theSame': 'same'

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

  showAction: =>
    @el.closest('.content').find('.js-changes').removeClass('hidden')

  changes: =>
    @hasChanges

  create: (e) =>
    e.preventDefault()
    @hasChanges = true
    @showAction()
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
    @hasChanges = true
    @showAction()
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
  hasChanges: false
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
    @strings = []
    @times   = []
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
    @changesAvailable = false
    @$('.js-Item').each( (e) ->
      id = $(this).data('id')
      ui.updateRow(id)
    )
    if @changesAvailable
      @showAction()

  showAction: =>
    @el.closest('.content').find('.js-changes').removeClass('hidden')

  changes: =>
    @hasChanges

  reset: (e) ->
    e.preventDefault()
    @hasChanges = true
    field       = $(e.target).closest('tr').find('.js-Item')
    id          = field.data('id')
    source      = field.data('source')
    initial     = field.data('initial')
    format      = field.data('format')

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
    @hasChanges = true
    id          = $( e.target ).data('id')
    source      = $( e.target ).data('source')
    format      = $( e.target ).data('format')
    target      = $( e.target ).val()

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
      @changesAvailable = true
      reset.show()
      reset.closest('tr').addClass('warning')
    else
      reset.hide()
      reset.closest('tr').removeClass('warning')

App.Config.set( 'Translation', { prio: 1800, parent: '#system', name: 'Translations', target: '#system/translation', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )