InstanceMethods =
  parent: ->
    throw 'Please implement parent method, fetching parent object'

  uiUrl: ->
    kb_locale = App.KnowledgeBaseLocale.localeFor(@)
    @parent().uiUrl(kb_locale)

  fullyLoaded: ->
    if @ instanceof App.KnowledgeBaseAnswerTranslation
      return @content() isnt null

    true

  defaultSearchResultAttributes: ->
    kb_locale = App.KnowledgeBaseLocale.localeFor(@)

    {
      display:    @title
      id:         @id
      url:        @uiUrl()
    }

  searchResultAttributes: ->
    @defaultSearchResultAttributes()

App.KnowledgeBaseTranslationable =
  extended: ->
    @include InstanceMethods
