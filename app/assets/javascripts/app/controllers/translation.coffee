class Translation extends App.ControllerSubContent
  requiredPermission: 'admin.translation'
  header: __('Translations')
  events:
    'click .js-resetChanges': 'resetChanges'
  initialRenderingDone: false

  constructor: ->
    super
    @locale = App.i18n.get()
    @render()
    @controllerBind('i18n:translation_update_todo', =>
      @load('i18n:translation_update_todo')
    )
    @controllerBind('i18n:translation_update_list', =>
      @load('i18n:translation_update_list')
    )
    @controllerBind('i18n:translation_update', =>
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
      inlineTranslationKey: App.Browser.hotkeys().split('+').reverse().join('+') + '+t'
    )
    @load('render')

  load: (event) =>
    @ajax(
      id:    'translations_admin'
      type:  'GET'
      url:   "#{@apiPath}/translations/admin/lang/#{@locale}"
      processData: true
      success: (data, status, xhr) =>
        @initialRenderingDone = true
        @times                = []
        @stringsNotTranslated = []
        @stringsTranslated    = []
        for item in data.list
          if item[1] is 'FORMAT_DATE' or item[1] is 'FORMAT_DATETIME'
            @times.push item
          else
            if item[2] is ''
              @stringsNotTranslated.push item
            else
              @stringsTranslated.push item

        if !@translationToDo || event is 'render'
          @translationToDo = new TranslationToDo(
            el:             @$('.js-ToDo')
            locale:         @locale
            updateOnServer: @updateOnServer
            getAttributes:  @getAttributes
          )
        if !event || event is 'i18n:translation_update_todo'|| event is 'render'
          @translationToDo.update(
            stringsNotTranslated: @stringsNotTranslated
            stringsTranslated:    @stringsTranslated
            times:                @times
          )
        if !@translationList || event is 'render'
          @translationList = new TranslationList(
            el:             @$('.js-List')
            locale:         @locale
            updateOnServer: @updateOnServer
            getAttributes:  @getAttributes
          )
        if !event || event is 'i18n:translation_update_list'|| event is 'render'
          @translationList.update(
            stringsNotTranslated: @stringsNotTranslated
            stringsTranslated:    @stringsTranslated
            times:                @times
          )
        @toggleAction()
    )

  show: =>
    return if @initialRenderingDone is false
    @render()

  hide: =>
    @rerender()

  release: =>
    @rerender()

  rerender: =>
    rerender = ->
      App.Event.trigger('ui:rerender')
    if @translationList && @translationList.changes()
      App.Delay.set(rerender, 400)

  showAction: =>
    @$('.js-changes').removeClass('hidden')

  hideAction: =>
    @el.closest('.content').find('.js-changes').addClass('hidden')

  toggleAction: =>
    if @$('.js-Reset:visible').length > 0
      @showAction()
    else
      @hideAction()

  resetChanges: =>
    @loader = new App.ControllerModalLoading(
      head:      __('Reset changes')
      message:   __('Resetting changes…')
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

  updateOnServer: (params, event) =>

    # update runtime if same language is used
    if App.i18n.get() is params.locale
      App.i18n.setMap(params.source, params.target)

    # remove not needed attributes
    delete params.field

    if params.id
      if params.target is ''
        method = 'DELETE'
        url    = "#{@apiPath}/translations/#{params.id}"
      else
        method = 'PUT'
        url    = "#{@apiPath}/translations/#{params.id}"
    else
      method = 'POST'
      url    = "#{@apiPath}/translations"

    @ajax(
      id:          'translations'
      type:        method
      url:         url
      data:        JSON.stringify(params)
      processData: false
      success: (data, status, xhr) =>
        if event
          App.Event.trigger(event)
        @toggleAction()
    )

  getAttributes: (e) =>
    field  = $(e.target).closest('tr').find('.js-Item')
    params =
      id:      field.data('id')
      source:  field.data('source')
      initial: field.data('initial') || ''
      target:  field.val()
      locale:  @locale
      field:   field

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

    if _.isEmpty(@stringsNotTranslated)
      @html ''
      return

    @html App.view('translation/todo')(
      list: @stringsNotTranslated
    )

  create: (e) =>
    e.preventDefault()
    params = @getAttributes(e)
    return if !params.target

    # remove from not translated list
    $(e.target).closest('tr').remove()

    # remote update
    params.target_initial = ''
    @updateOnServer(params, 'i18n:translation_update_list')

  same: (e) =>
    e.preventDefault()
    @hasChanges = true
    params = @getAttributes(e)

    # remove from not translated list
    $(e.target).closest('tr').remove()

    # remote update
    params.target_initial = ''
    params.target = params.source
    @updateOnServer(params, 'i18n:translation_update_list')

class TranslationList extends App.Controller
  hasChanges: false
  events:
    'blur .js-translated input':      'updateItem'
    'click .js-translated .js-Reset': 'resetItem'

  constructor: ->
    super

  update: (data) =>
    for key, value of data
      @[key] = value
    @render()

  render: =>
    return if _.isEmpty(@stringsTranslated) && _.isEmpty(@times)
    @html App.view('translation/list')(
      times:                @times
      strings:              @stringsTranslated
    )

  changes: =>
    @hasChanges

  resetItem: (e) ->
    e.preventDefault()
    @hasChanges = true
    params = @getAttributes(e)

    # remote reset
    params.target = params.initial
    @updateOnServer(params, 'i18n:translation_update')

  updateItem: (e) ->
    e.preventDefault()
    @hasChanges = true
    params = @getAttributes(e)
    return if !params.target

    # local update
    @updateRow(params.id)

    # remote update
    @updateOnServer(params)

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

App.Config.set('Translation', { prio: 1800, parent: '#system', name: __('Translations'), target: '#system/translation', controller: Translation, permission: ['admin.translation'] }, 'NavBarAdmin' )
