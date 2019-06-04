class App.KnowledgeBaseLocale extends App.Model
  @configure 'KnowledgeBaseLocale', 'knowledge_base_id', 'system_locale_id', 'primary'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/knowledge_base/locales'

  systemLocale: ->
    App.Locale.find(@system_locale_id)

  urlSuffix: ->
    "locale/#{@systemLocale().locale}"

  @localeFor: (object) ->
    if object.kb_locale_id is undefined
      throw "This object doesn't have locale"

    App.KnowledgeBaseLocale.find object.kb_locale_id

  applyOntoPath: (path) ->
    path.replace /\/locale\/[\w-]{2,5}/, "/#{@urlSuffix()}"

  attributesForRendering: (path, options = {}) ->
    {
      url:   @applyOntoPath(path)
      title: @systemLocale().name
    }

  @detect: (knowledge_base) ->
    locale    = App.Locale.findByAttribute('locale', App.i18n.get())

    kb_locale = App.KnowledgeBaseLocale
      .all()
      .filter (elem) ->
        elem.knowledge_base_id is knowledge_base.id and elem.system_locale_id is locale.id
      .pop()

    kb_locale || knowledge_base.primaryKbLocale()
