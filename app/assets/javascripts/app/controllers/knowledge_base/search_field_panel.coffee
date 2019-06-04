class App.KnowledgeBaseSearchFieldPanel extends App.Controller
  elements:
    '.js-placeholderEmpty':   'emptyPlaceholder'
    '.js-placeholderError':   'errorPlaceholder'
    '.js-results':            'resultsContainer'

  context:   undefined
  kb_locale: null

  #callbacks
  willStart: null
  didEnd:    null

  constructor: ->
    super
    @html App.view('knowledge_base/search_field_panel')()

    @widget = new App.KnowledgeBaseSearchFieldWidget(
      el:        @$('.searchfield')
      kb_locale: @kb_locale
      context:   @context

      willStart: @widgetWillStart
      didEnd:    @widgetDidEnd

      willStartLoading: @widgetWillStartLoading

      renderError: @renderError
      renderResults: @renderResults
    )

  clear: =>
    @resultsContainer.empty()
    @errorPlaceholder.addClass('hide')
    @emptyPlaceholder.addClass('hide')

  widgetWillStart: =>
    @willStart?()

  widgetDidEnd: =>
    @clear()
    @didEnd?()

  widgetWillStartLoading: =>
    @clear()

  renderError: (text) =>
    @errorPlaceholder
      .removeClass('hide')
      .find('.help-block--inner')
      .text(App.i18n.translateInline(text))

  renderResults: (results, originalQuery) =>
    @clear()

    if results.result.length == 0
      @emptyPlaceholder.removeClass('hide')
      return

    suffix     = @buildReturnSuffix(originalQuery)
    return_path = App.Utils.joinUrlComponents(@return_path, originalQuery)

    views = results
      .result
      .map (elem, index) ->
        details = results.details[index]
        klass_name = elem.type.replace /::/g, ''

        object = App[klass_name].find(elem.id)

        new App.KnowledgeBaseSearchItem(
          object:     object
          meta:       elem
          details:    details
          pathSuffix: suffix
          return_path: return_path
        )

      .map (elem) -> elem.el

    @resultsContainer.append views

  buildReturnSuffix: (query) ->
    encodeURIComponent App.Utils.joinUrlComponents(@return_path, query)
