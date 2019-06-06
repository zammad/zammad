class App.KnowledgeBaseSearchItem extends App.Controller
  tag: 'li'
  className: 'section'

  events:
    'click a': 'searchLinkClicked'

  constructor: ->
    super

    @render()

  data: ->
    output = @details || {}
    output['url']   = @object?.uiUrl("search-return/#{@pathSuffix}") || '#'
    output['state'] = @object.parent().attributesForRendering(App.KnowledgeBaseLocale.localeFor(@object)).state
    output

  render: ->
    @html App.view('knowledge_base/search_item')(data: @data())

  searchLinkClicked: -> # setup history and let it continue, no need to prevent default action or bubbling
    if window.history? and @return_path?
      window.history.replaceState(null, null, @return_path)
