class App.KnowledgeBaseSearchItem extends App.Controller
  tag: 'li'
  className: 'section'

  events:
    'click a': 'searchLinkClicked'

  constructor: ->
    super

    @render()

  data: ->
    extraAttributes = @object.parent().attributesForRendering(App.KnowledgeBaseLocale.localeFor(@object))

    output = @details || {}
    output.url      = @object?.uiUrl("search-return/#{@pathSuffix}") || '#'
    output.state    = extraAttributes.state
    output.iconFont = extraAttributes.iconFont
    output

  render: ->
    @html App.view('knowledge_base/search_item')(data: @data(), iconset: @object.parent().knowledge_base().iconset)

  searchLinkClicked: -> # setup history and let it continue, no need to prevent default action or bubbling
    if window.history? and @return_path?
      window.history.replaceState(null, null, @return_path)
