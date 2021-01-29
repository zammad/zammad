class App.KnowledgeBaseNavigation extends App.Controller
  @extend(Spine.Events)

  events:
    'click .js-search': 'clickedToggleSearch'

  elements:
    '.js-edit': 'editButton'

  constructor: ->
    super
    @render()

    @controllerBind('knowledge_base::navigation::rerender', => @needsUpdate())

    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', =>
      @needsUpdate()

  buildCrumbsForRendering: (array, kb_locale, action) ->
    if action is 'search'
      action = null

    if !kb_locale
      return []

    array
      .filter (elem) ->
        elem != undefined and elem != null
      .map (elem) =>
        if typeof elem is 'string'
          return { title: elem }

        @listenToChangesOn(elem)
        elem.attributesForRendering(kb_locale, action: action)

  listenToChangesOn: (object) ->
    locale = @parentController.kb_locale()

    if !locale
      return

    @stopListening object, 'refresh'
    @listenToOnce  object.translationBindlableObject(locale.id), 'refresh', (obj) =>
      @needsUpdate()

  show: (object, action) ->
    @savedAction = action

    if @dontRenderFor(object)
      return

    # coffeelint: disable=indentation
    crumbs = if title = @calculateTitle(object, action)
               [@parentController.getKnowledgeBase(), title]
             else
               @breadcrumbTo(object).reverse()
    # coffeelint: enable=indentation

    crumbsForRendering = @buildCrumbsForRendering(crumbs, @parentController.kb_locale(), action)

    @render(crumbsForRendering, object, action)
    @savedParams = object

  calculateTitle: (object, action) ->
    if action is 'search'
      App.i18n.translateInline 'Search'
    else if !object
      App.i18n.translateInline 'Not found'

  dontRenderFor: (object) ->
    if object instanceof App.Model
      object.isNew() && !object.isFresh
    else
      false

  needsUpdate: ->
    @show(@savedParams, @savedAction)

  selectedLocaleDisplay: ->
    @parentController.kb_locale()?.systemLocale().alias || '-'

  render: (crumbs = [], object = null, action = null) ->
    kb_locale = @parentController.kb_locale()
    return if !kb_locale

    @html App.view('knowledge_base/navigation')(
      crumbs:      crumbs
      kbLocales:   @kbLocaleOptions(object, kb_locale, action)
      search:      @searchOptions(object, kb_locale, action)
      edit:        @editOptions(object, kb_locale, action)
      externalUrl: @externalUrl(object, kb_locale, action)
      iconset:     @parentController.getKnowledgeBase().iconset
    )

  kbLocaleOptions: (object, kb_locale, action) ->
    {
      selected:   kb_locale
      collection: @kb_locales()
    }

  searchOptions: (object, kb_locale, action) ->
    enabled = action is 'search'

    url = if enabled == true
            @toggleSearchSource || @parentController.getKnowledgeBase()?.uiUrl(kb_locale)
          else
            @parentController.getKnowledgeBase()?.uiUrl(kb_locale, 'search')

    {
      enabled: enabled
      url:     url
    }

  editOptions: (object, kb_locale, action) ->
    enabled = action is 'edit'

    {
      url:       object?.uiUrl(kb_locale, if !enabled then 'edit')
      enabled:   enabled
      available: @parentController.isEditor()
    }


  externalUrl: (object, kb_locale, action) ->
    if action and action != 'edit'
      return

    if !(object?.visiblePublicly?(kb_locale) or (object?.translation?(kb_locale?.id)? and @parentController.isEditor()))
      return

    object.publicBaseUrl(kb_locale)

  kb_locales: ->
    path = '#' + @parentController.lastParams.match.input

    @parentController
      .getKnowledgeBase()
      .kb_locales()
      .map (elem) -> elem.attributesForRendering(path)

  toggleSearchSource: undefined

  clickedToggleSearch: ->
    if @savedAction is 'search'
      return

    @toggleSearchSource = location.hash

  breadcrumbTo: (object) ->
    if !object
      return []

    output = switch object.constructor
      when App.KnowledgeBaseAnswer
        @breadcrumbToAnswer(object)
      when App.KnowledgeBaseCategory
        @breadcrumbToCategory(object)
      when App.KnowledgeBase
        @breadcrumbToKb(object)

  breadcrumbToAnswer: (answer) ->
    [answer].concat @breadcrumbToCategory(answer.category())

  breadcrumbToCategory: (category) ->
    array = [category]

    while parent = (parent || category).parent()
      array = array.concat parent

    array.concat @breadcrumbToKb(category.knowledge_base())

  breadcrumbToKb: (kb) ->
    [kb]
