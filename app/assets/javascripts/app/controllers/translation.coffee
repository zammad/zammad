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
    @locale = App.i18n.get()
    @render()
    @bind(
      'i18n:translation_update',
      =>
        @load()
    )

  render: =>
    locales = App.Locale.all()
    currentLanguage = @locale
    for locale in locales
      if locale.locale is @locale
        currentLanguage = locale.name
    @html App.view('translation/index')(
      currentLanguage: currentLanguage
    )
    @load()

  load: =>
    @ajax(
      id:    'translations_admin'
      type:  'GET'
      url:   "#{@apiPath}/translations/admin/lang/#{@locale}"
      processData: true
      success: (data, status, xhr) =>
        @times                = []
        @stringsNotTranslated = []
        @stringsTranslated    = []
        for item in data.list

          # if item has changed
          if item[2] isnt item[3]
            @showAction()

          # collect items
          if item[4] is 'time'
            @times.push item
          else
            if item[2] is ''
              @stringsNotTranslated.push item
            else
              @stringsTranslated.push item

        if !@translationToDo
          @translationToDo = new TranslationToDo(
            el:     @$('.js-ToDo')
            locale: @locale
          )
        @translationToDo.update(
          stringsNotTranslated: @stringsNotTranslated
          stringsTranslated:    @stringsTranslated
          times:                @times
        )
        if !@translationList
          @translationList = new TranslationList(
            el:     @$('.js-List')
            locale: @locale
          )
        @translationList.update(
          stringsNotTranslated: @stringsNotTranslated
          stringsTranslated:    @stringsTranslated
          times:                @times
        )
    )

  showAction: =>
    @$('.js-changes').removeClass('hidden')

  release: =>
    rerender = ->
      App.Event.trigger('ui:rerender')
      console.log('rr')
    if @translationList.changes()
      App.Delay.set(rerender, 400)
    console.log('111', @translationList.changes())

  hideAction: =>
    @el.closest('.content').find('.js-changes').addClass('hidden')

  pushChanges: =>
    @loader = new App.ControllerModalLoading(
      head:      'Push my changes'
      message:   'Pushing translations to i18n.zammad.com'
      container: @el.closest('.content')
    )

    @ajax(
      id:          'translations'
      type:        'PUT'
      url:         "#{@apiPath}/translations/push"
      data:        JSON.stringify(locale: @locale)
      processData: false
      success: (data, status, xhr) =>
        @loader.update('Thanks for contributing!')
        @loader.hideIcon()
        @loader.hide(2)
      error: =>
        @loader.hide()
    )

  resetChanges: =>
    @loader = new App.ControllerModalLoading(
      head:      'Reset changes'
      message:   'Reseting changes...'
      container: @el.closest('.content')
    )

    @ajax(
      id:          'translations'
      type:        'POST'
      url:         "#{@apiPath}/translations/reset"
      data:        JSON.stringify(locale: @locale)
      processData: false
      success: (data, status, xhr) =>
        App.Event.trigger('i18n:translation_update')
        @hideAction()
        @loader.hide()
      error: =>
        @loader.hide()
    )

  syncChanges: =>
    @loader = new App.ControllerModalLoading(
      head:      'Get latest translations'
      message:   'Getting latest translations from i18n.zammad.com'
      container: @el.closest('.content')
    )

    hide = =>
      App.Event.trigger('i18n:translation_update')
      @hideAction()
      @loader.hide(1)

    locales = App.Locale.all()
    locale = locales.shift()
    @_syncChanges(locale, locales, @loader, hide)

  _syncChanges: (locale, locales, loader, hide) =>
    @ajax(
      id:          'translations'
      type:        'GET'
      url:         "#{@apiPath}/translations/sync/#{locale.locale}"
      processData: false
      complete: (data, status, xhr) =>
        loader.update(locale.name, false)
        locale = locales.shift()
        if _.isEmpty(locales)
          hide()
          return
        @_syncChanges(locale, locales, loader, hide)
      )

class TranslationToDo extends App.Controller
  events:
    'click .js-create':  'create'
    'click .js-theSame': 'same'

  constructor: ->
    super

  update: (data) =>
    for key, value of data
      @[key] = value
    @render()

  render: =>

    if !App.i18n.notTranslatedFeatureEnabled(@locale)
      @html App.view('translation/english')()
      return

    if !App.i18n.getNotTranslated(@locale) && _.isEmpty(@stringsNotTranslated)
      @html ''
      return

    if App.i18n.getNotTranslated(@locale)
      for key, value of App.i18n.getNotTranslated(@locale)
        item = [ '', key, '', '']
        @stringsNotTranslated.push item

    @html App.view('translation/todo')(
      list: @stringsNotTranslated
    )

  create: (e) =>
    e.preventDefault()
    field  = $(e.target).closest('tr').find('.js-Item')
    id     = field.data('id')
    source = field.data('source')
    format = 'string'
    target = field.val()
    return if !target

    # remove from not translated list
    $(e.target).closest('tr').remove()

    # local update
    App.i18n.removeNotTranslated(@locale, source)

    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap(source, target, 'string')

    # remote update
    params =
      locale:         @locale
      source:         source
      target:         target
      target_initial: ''

    if id
      method    = 'PUT'
      params.id = id
      url       = "#{@apiPath}/translations/#{id}"
    else
      method = 'POST'
      url    = "#{@apiPath}/translations"

    @ajax(
      id:          'translations'
      type:        method
      url:         url
      data:        JSON.stringify(params)
      processData: false
      success: (data, status, xhr) ->
        App.Event.trigger('i18n:translation_update')
    )

  same: (e) =>
    e.preventDefault()
    @hasChanges = true
    field  = $(e.target).closest('tr').find('.js-Item')
    source = field.data('source')

    # remove from not translated list
    $(e.target).closest('tr').remove()

    # local update
    App.i18n.removeNotTranslated(@locale, source)

    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap(source, source, 'string')

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
      success: (data, status, xhr) ->
        App.Event.trigger('i18n:translation_update')
    )

class TranslationList extends App.Controller
  hasChanges: false
  events:
    'blur .js-translated input':          'updateItem'
    'click .js-translated .js-Reset':     'resetItem'

  constructor: ->
    super

  update: (data) =>
    for key, value of data
      @[key] = value
    @render()

  render: =>
    @html App.view('translation/list')(
      times:   @times
      strings: @stringsTranslated
    )

  changes: =>
    @hasChanges

  resetItem: (e) ->
    e.preventDefault()
    @hasChanges = true
    field       = $(e.target).closest('tr').find('.js-Item')
    id          = field.data('id')
    source      = field.data('source')
    initial     = field.data('initial')
    format      = field.data('format')

    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap(source, initial, format)

    # locale reset
    field.val(initial)
    @updateRow(id)

    # remote reset
    params =
      id:     id
      target: initial

    @ajax(
      id:          'translations'
      type:        'PUT'
      url:         "#{@apiPath}/translations/#{id}"
      data:        JSON.stringify(params)
      processData: false
      success: (data, status, xhr) ->
        App.Event.trigger('i18n:translation_update')
    )

  updateItem: (e) ->
    e.preventDefault()
    @hasChanges = true
    field  = $(e.target).closest('tr').find('.js-Item')
    id     = field.data('id')
    source = field.data('source')
    format = field.data('format')
    target = field.val()
    return if !target

    # local update
    @updateRow(id)

    # update runtime if same language is used
    if App.i18n.get() is @locale
      App.i18n.setMap(source, target, format)

    # remote update
    params =
      id:     id
      target: target

    @ajax(
      id:          'translations'
      type:        'PUT'
      url:         "#{@apiPath}/translations/#{id}"
      data:        JSON.stringify(params)
      processData: false
      success: (data, status, xhr) ->
        App.Event.trigger('i18n:translation_update')
    )

  updateRow: (id) =>
    field   = @$("[data-id=#{id}]")
    current = field.val()
    initial = field.data('initial')
    reset   = field.closest('tr').find('.js-Reset')
    if current isnt initial
      @changesAvailable = true
      reset.removeClass('hidden')
      reset.closest('tr').addClass('warning')
    else
      reset.addClass('hidden')
      reset.closest('tr').removeClass('warning')

App.Config.set('Translation', { prio: 1800, parent: '#system', name: 'Translations', target: '#system/translation', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
