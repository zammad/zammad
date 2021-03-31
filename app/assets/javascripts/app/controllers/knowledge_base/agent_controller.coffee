class App.KnowledgeBaseAgentController extends App.Controller
  className: 'knowledge-base vertical'
  name:      'Knowledge Base'

  elements:
    '.js-body':       'body'
    '.js-navigation': 'navigation'
    '.js-sidebar':    'sidebar'

  constructor: (params) ->
    super
    @controllerBind('config_update_local', (data) => @configUpdated(data))

    if @permissionCheck('knowledge_base.*') and App.Config.get('kb_active')
      @updateNavMenu()
    else if App.Config.get('kb_active_publicly')
      @loadInitial(
        {},
        success: (data, status, xhr) =>
          @updateNavMenu()
      )

  configUpdated: (data) ->
    if data.name isnt 'kb_active' and data.name isnt 'kb_active_publicly'
      return

    @updateNavMenu()

  firstRunIfNeeded: ->
    if @firstRunDone
      return

    @firstRunDone = true

    @coordinator = new App.KnowledgeBaseEditorCoordinator(parentController: @)

    @fetchAndRender()

    @controllerBind('ui:rerender',
      =>
        @render(true)
        @contentController?.url = null
        @lastParams.selectedSystemLocale = App.KnowledgeBaseLocale.detect(@getKnowledgeBase()).systemLocale()
        @show(@lastParams)
    )

    @controllerBind('kb_data_changed', (pushed_data) =>
      key = "kb_pull_#{pushed_data.class}_#{pushed_data.id}"

      App.Delay.set( =>
        @loadChange(pushed_data)
      , 1000, key, 'kb_data_changed_loading')
    )
    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', =>
      return if !@displayingError

      object = @constructor.pickObjectUsing(@lastParams, @)

      if !@objectVisibleInternally(object)
        return

      @renderControllers(@lastParams)

    @checkForUpdates()

  loadChange: (pushed_data) =>
    url = pushed_data.url + '?full=true'

    if pushed_data.class is 'KnowledgeBase::Answer'
      object = App.KnowledgeBaseAnswer.find pushed_data.id

      # coffeelint: disable=indentation
      loaded_ids = object
                     ?.translations()
                     .map (elem) -> elem.content()?.id
                     .filter (elem) -> elem isnt undefined
      # coffeelint: enable=indentation

      if loaded_ids and loaded_ids.length isnt 0
        url += '&include_contents=' + loaded_ids.join(',')

    @ajax(
      id: "kb_pull_#{pushed_data.class}_#{pushed_data.id}"
      type: 'GET'
      url: url
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)

        @notifyChangeLoaded()
      error: (xhr) =>
        if xhr.status != 404
          return

        klassName = pushed_data.class.replace(/::/g,'')

        if object = App[klassName]?.find(pushed_data.id)
          object.remove(clear: true)
          @notifyChangeLoaded()
    )

  objectVisibleInternally: (object) ->
    if !object
      return false
    else if object instanceof App.KnowledgeBaseAnswer and !object.exists()
      return false
    else if object instanceof App.KnowledgeBaseCategory and !object.visibleInternally(@kb_locale())
      return false

    true

  notifyChangeLoaded: ->
    App.KnowledgeBase.trigger('kb_data_change_loaded')

  active: (state) ->
    return @shown if state is undefined
    @shown = state

  featureActive: ->
    (@permissionCheck('knowledge_base.*') and App.Config.get('kb_active')) or (App.Config.get('kb_active_publicly') and App.KnowledgeBase.first()?)

  activeLocaleSuffix: ->
    @kb_locale().urlSuffix()

  requiredPermissionSuffix: (params) ->
    if params.action is 'edit'
      'editor'
    else
      '*'

  show: (params) =>
    @firstRunIfNeeded()
    @navupdate '#knowledge_base'

    @bodyModal?.close()
    @bodyModal = null

    if !@permissionCheckRedirect("knowledge_base.#{@requiredPermissionSuffix(params)}")
      return

    if @loaded && @rendered && @lastParams && !params.knowledge_base_id && @contentController && @kb_locale()?
      @navigate @lastParams.match[0] , { hideCurrentLocationFromHistory: true }
      return

    if @contentController && @contentController.url is params.match[0]
      @title @lastTitle
      @contentController.restoreVisibility?()
      return

    @rendered = true

    @lastParams = params

    if @loaded and params.selectedSystemLocale is null and params.selectedSystemLocalePresent
      @renderError()
      return

    @displayingError = false

    if @loaded
      if params.knowledge_base_id
        @renderControllers(params)
      else
        if (kb = App.KnowledgeBase.all()[0])
          @navigate kb.uiUrl(App.KnowledgeBaseLocale.detect(kb)), { hideCurrentLocationFromHistory: true }
        else
          @renderScreenErrorInContent('No Knowledge Base created')
    else
      @pendingParams = params

  renderScreenErrorInContent: (text) ->
    @contentController = undefined
    @renderScreenError(detail: text, el: @$('.page-content'))
    @displayingError = true

  renderControllers: (params) ->
    object = @constructor.pickObjectUsing(params, @)

    if !object || (!@isEditor() && !object.visibleInternally(@kb_locale()))
      @renderNotFound()
      return

    titleSuffix = if !(object instanceof App.KnowledgeBase)
                    object.guaranteedTitle(@kb_locale().id)
                  else if params.action is 'search'
                    App.i18n.translateInline('Search')
                  else
                    ''

    @updateTitle(titleSuffix)

    klass = @contentControllerClass(params)
    @contentController?.releaseController()
    @contentController = @buildUsing(klass, params, object)
    @navigationController?.show(object, params.action)
    @sidebarController?.show(object, params.action)

  updateTitle: (titleSuffix) ->
    newTitle = @getKnowledgeBase()?.guaranteedTitle(@kb_locale()?.id) || ''

    if titleSuffix != ''
      if newTitle
        newTitle += ' - '

      newTitle += titleSuffix

    @title newTitle
    @lastTitle = newTitle

  contentControllerClass: (params) ->
    if params.action is 'search'
      return App.KnowledgeBaseSearchController

    if params.action is 'edit'
      return App.KnowledgeBaseContentController

    if params.answer_id
      App.KnowledgeBaseReaderController
    else
      App.KnowledgeBaseReaderListController

  edit: false

  renderNotFound: ->
    title = App.i18n.translateInline('Not Found')
    @updateTitle(title)
    @navigationController?.show(undefined, title)
    @renderScreenErrorInContent('The page was not found')
    @sidebarController?.hide()

  renderNotAvailableAnymore: ->
    @updateTitle(App.i18n.translateInline('Not Available'))
    @renderScreenErrorInContent('The page is not available anymore')

  renderError: ->
    @bodyModal?.close()

    url = App.Utils.joinUrlComponents @lastParams.effectivePath, @getKnowledgeBase().primaryKbLocale().urlSuffix()

    @bodyModal = new App.ControllerModal(
      head:          'Locale not found'
      contentInline: "<a href='#{url}'>Open in primary locale</a>"
      buttonClose:   false
      buttonSubmit: false
      backdrop: 'static'
      keyboard: false
      container: @el
    )

  kb_locale: ->
    kb = @getKnowledgeBase()
    return if !kb

    if @lastParams.selectedSystemLocale
      kb.kb_locales().filter((elem) =>  elem.system_locale_id == @lastParams.selectedSystemLocale.id)[0]

  getKnowledgeBase: ->
    App.KnowledgeBase.find(@lastParams.knowledge_base_id)

  fetchAndRender: =>
    @fetch(true, true)

  fetch: (showLoader, processLoaded) ->
    if showLoader
      @startLoading()

    loaded_content_ids = App.KnowledgeBaseAnswerTranslationContent.all().map (elem) -> elem.id

    params = {
      answer_translation_content_ids: loaded_content_ids
    }

    @loadInitial(
      params,
      success: (data, status, xhr) =>
        if showLoader
          @stopLoading()

        if processLoaded
          @processLoaded()
      ,
      error: (xhr) =>
        if showLoader
          @stopLoading()
    )

  loadInitial: (params, options = {}) =>
    @ajax(
      id:          'knowledge_bases_init'
      type:        'POST'
      url:         @apiPath + '/knowledge_bases/init'
      data:        JSON.stringify(params)
      processData: true
      success:     (data, status, xhr) =>
        @loaded = true
        @loadKbData(data)

        options.success?(data, status, xhr)
      error:       (xhr) ->
        options.error?(xhr)
    )

  loadKbData: (data) ->
    App.Collection.loadAssets(data)

    for elem in @calculateIdsToDelete(data)
      for id in elem.ids
        App[elem.modelName].find(id)?.remove(clear: true)

  calculateIdsToDelete: (data) ->
    Object
      .keys(data)
      .filter (elem) -> elem.match(/^KnowledgeBase/)
      .map (model) ->
        newIds = Object.keys data[model]
        oldIds = App[model].all().map (elem) -> elem.id
        diff   = oldIds.filter (elem) -> !_.includes(newIds, String(elem))

        {modelName: model, ids: diff}
      , {}

  processLoaded: ->
    @render(true)

    if @pendingParams
      @show(@pendingParams)
      @pendingParams = undefined

  render: (force = false) =>
    @html App.view('knowledge_base/agent')()

    @navigationController = new App.KnowledgeBaseNavigation(
      el: @$('.js-navigation')
      parentController: @
    )

    @sidebarController = new App.KnowledgeBaseSidebar(
      el: @$('.js-sidebar')
      parentController: @
    )

  isEditor: ->
    App.User.current().permission('knowledge_base.editor')

  checkForUpdates: ->
    @interval(@checkUpdatesAction, 10 * 60 * 1000, 'kb_interval_check')

  checkUpdatesAction: =>
    if !@loaded
      return

    @fetch(false, false)

  buildUsing: (klass, params, object) ->
    new klass(
      el:                   @$('.page-content')
      object:               object
      parentController:     @
      selectedSystemLocale: params.selectedSystemLocale
      url:                  params.match[0]
    )

  onclick: ->
    !(@permissionCheck('knowledge_base.*') and App.Config.get('kb_active')) and (App.Config.get('kb_active_publicly') and App.KnowledgeBase.first()?)

  accessoryIcon: ->
    return if !@onclick()

    'external'

  clicked: ->
    window.open(App.KnowledgeBase.first().publicBaseUrl(), '_blank')

  @pickObjectUsing: (params, parentController) ->
    kb = parentController.getKnowledgeBase()
    return if !kb

    if answer_id = params['answer_id']
      App.KnowledgeBaseAnswer.find(answer_id)
    else if category_id = params['category_id']
      App.KnowledgeBaseCategory.find(category_id)
    else if knowledge_base_id = params['knowledge_base_id']
      kb

App.Config.set('KnowledgeBase', { controller: 'KnowledgeBaseAgentController' }, 'permanentTask')
App.Config.set('KnowledgeBase', { prio: 1150, parent: '', name: 'Knowledge Base', target: '#knowledge_base', key: 'KnowledgeBase', class: 'knowledge-base', shown: false}, 'NavBar')
