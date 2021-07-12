InstanceMethods =
  translations: ->
    klass = @constructor.translatableClass()
    key = @constructor.translatableForeignKey()

    klass.all().filter (elem) => elem[key] == @id

  translation: (kb_locale_id) ->
    return null if kb_locale_id is null or kb_locale_id is undefined
    @translations().filter((elem) -> elem.kb_locale_id == kb_locale_id)[0]

  primaryTranslation: ->
    primaryKbLocale = @knowledge_base().primaryKbLocale()
    @translation(primaryKbLocale.id)

  attributesIncludingTranslation: (kb_locale_id) ->
    output = @attributes()
    output.translation = @translation(kb_locale_id)?.attributes()
    output

  attributesForRendering: (kb_locale, options = {}) ->
    attrs = {
      id:    @id
      url:   @uiUrl(kb_locale, options.action)
      title: @guaranteedTitle(kb_locale.id)
      missingTranslation: @translation(kb_locale.id) is undefined
    }

    if @ instanceof App.KnowledgeBase
      attrs.icon  = 'knowledge-base'
      attrs.title = ''
      attrs.type  = 'base'

    if @ instanceof App.KnowledgeBaseCategory
      attrs.iconFont = true
      attrs.icon     = @category_icon
      attrs.count    = @countDeepAnswers()
      attrs.state    = @visibilityState(kb_locale)
      attrs.type     = 'category'

    if @ instanceof App.KnowledgeBaseAnswer
      attrs.icon  = 'knowledge-base-answer'
      attrs.state = @can_be_published_state()
      attrs.tags  = @tags
      attrs.type  = 'answer'

    attrs.icons = {}

    if attrs.missingTranslation
      attrs.icons['danger'] = true

    attrs

  writeMethod: ->
    if @id then 'PATCH' else 'POST'

  prepareNestedParams: (params, kb_locale_id) ->
    if @baseParams
      params = _.extendOwn(@baseParams(), params)

    translation_params = params['translation']
    delete params['translation']

    if translation = @translation(kb_locale_id)
      translation_params['id'] = translation.id
    else
      translation_params['kb_locale_id'] = kb_locale_id

    if @constructor.translatableClass().processAttributes
      translation_params = @constructor.translatableClass().processAttributes(translation_params)

    params['translations_attributes'] = [translation_params]
    params

  objectActionName: ->
    action = if @isNew() then 'New' else 'Edit'
    "#{action} #{@objectName()}"

  removeTranslations: (options = {}) ->
    for translation in @translations()
      translation.remove(options)

  removeIncludingTranslations: (options = {}) ->
    @removeTranslations(options)
    @remove(options)

  guaranteedTranslation: (kb_locale_id) ->
    @translation(kb_locale_id) || @primaryTranslation() || @translations()[0]

  guaranteedTitle: (kb_locale, placeholder = '-') ->
    @guaranteedTranslation(kb_locale)?.title || placeholder

  translationBindlableObject: (kb_locale_id) ->
    @translation(kb_locale_id) || @constructor.translatableClass()

App.KnowledgeBaseTranslatable =
  extended: ->
    @include InstanceMethods
