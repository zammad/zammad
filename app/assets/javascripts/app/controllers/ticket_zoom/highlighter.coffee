class App.TicketZoomHighlighter extends App.Controller
  elements:
    '.textBubble-content': 'articles'
    '.js-highlight-icon':  'highlighterControl'

  events:
    'click .js-highlight':      'toggleHighlight'
    'click .js-highlightColor': 'pickColor'

  colors: [
    {
      name: 'Yellow'
      color: '#f7e7b2'
    },
    {
      name: 'Green'
      color: '#bce7b6'
    },
    {
      name: 'Blue'
      color: '#b3ddf9'
    },
    {
      name: 'Pink'
      color: '#fea9c5'
    },
    {
      name: 'Purple'
      color: '#eac5ee'
    }
  ]

  activeColorIndex: 0
  highlightClassPrefix: 'highlight-'

  constructor: ->
    super

    return if @ticket.currentView() isnt 'agent'

    @currentHighlights = {}

    rangy.init()

    @highlighter = rangy.createHighlighter(document, 'TextRange')
    @addClassApplier entry for entry in @colors

    @setColor()
    @render()

    # store original highlight css data
    @storeOriginalHighlight()

  render: ->
    @html App.view('ticket_zoom/highlighter')
      colors: @colors
      activeColorIndex: @activeColorIndex

  highlighterInstance: =>
    @highlighter

  storeOriginalHighlight: =>
    @originalHighlight =
      fill: @highlighterControl.css('fill')
      opacity: @highlighterControl.css('opacity')

  restoreOriginalHighlight: =>
    return if !@originalHighlight
    @highlighterControl.css('fill', @originalHighlight.fill)
    @highlighterControl.css('opacity', @originalHighlight.opacity)

  highlightEnable: =>
    @isActive = true
    @highlighterControl.css('opacity', 1)
    @highlighterControl.css('fill', @activeColor)

    @refreshObserver()

  highlightDisable: =>
    @isActive = false
    @restoreOriginalHighlight()

    articles = @el.closest('.content').find('.textBubble')
    articles.removeAttr('data-highlightcolor')
    @refreshObserver()

  refreshObserver: =>
    articles = @el.closest('.content').find('.textBubble-content')
    articles.off('mouseup', @onMouseUp)
    articles.on('mouseup', @onMouseUp) #future: touchend
    articles.off('mousedown', @onMouseDown)
    articles.on('mousedown', @onMouseDown) #future: touchend

  # for testing purposes the highlights get stored in article preferences
  loadHighlights: (ticket_article_id) ->
    return if @ticket.currentView() isnt 'agent'
    article = App.TicketArticle.find(ticket_article_id)
    return if !article.preferences
    return if !article.preferences.highlight
    return if _.isEmpty(article.preferences.highlight)
    return if article.preferences.highlight is 'type:TextRange'
    return if @currentHighlights[ticket_article_id] is article.preferences.highlight
    @currentHighlights[ticket_article_id] = article.preferences.highlight
    @highlighter.deserialize(article.preferences.highlight)

  # the serialization creates one string for the entire ticket
  # containing the offsets and the highlight classes
  #
  # we have to check how it works with having open several tickets - it might break
  #
  # if classes can be changed in the admin interface
  # we have to watch out to not end up with empty highlight classes
  storeHighlights: (article_id) ->

    # cleanup marker
    data         = @highlighter.serialize()
    marker       = "$article-content-#{article_id}"
    items        = data.split('|')
    newDataArray = [ items.shift() ]
    for item in items
      if item.substr(item.length-marker.length, item.length) is marker
        newDataArray.push item
    data = newDataArray.join('|')

    # store
    article                          = App.TicketArticle.find(article_id)
    article.preferences['highlight'] = data
    article.save()

  # the colors is set via css classes (can't do it inline with rangy)
  # thus we have to create a stylesheet if the colors
  # can be changed in the admin interface
  addClassApplier: (entry) ->
    @highlighter.addClassApplier rangy.createCssClassApplier(@highlightClassPrefix + entry.name)

  setColor: ->
    @highlightClass = @highlightClassPrefix + @colors[@activeColorIndex].name
    @activeColor    = @colors[@activeColorIndex].color

    if @isActive
      articles = @el.closest('.content').find('.textBubble')
      articles.attr('data-highlightcolor', @colors[@activeColorIndex].name)

  toggleHighlight: (e) =>
    @mouseDownInside = false
    @mouseUpInside = false

    if @isActive
      $(e.currentTarget).removeClass('active')

      @highlightDisable()
    else
      @highlightEnable()
      selection = rangy.getSelection()
      # if there's already something selected,
      # don't go into highlight mode
      # just toggle the selected
      if !selection.isCollapsed
        @toggleHighlightAtSelection(@content, @article_id)
      #else
        # toggle ui
        #$(e.currentTarget).addClass('active')

        # activate selection background
        #@articles.attr('data-highlightcolor', @colors[@activeColorIndex].name)

  pickColor: (e) =>
    @$('.js-highlightColor .is-selected').removeClass('is-selected')
    $(e.currentTarget).find('.js-selectedIcon').addClass('is-selected')

    @activeColorIndex = $(e.currentTarget).attr('data-key')
    @setColor()

    @highlightEnable()

    # check if selection exists - highlight it or remove highlight
    @toggleHighlightAtSelection(@content, @article_id)

  onMouseDown: (e) =>
    if @updateSelectedArticle(e)
      @mouseDownInside = true
    else
      @mouseDownInside = false

  onMouseUp: (e) =>
    if @updateSelectedArticle(e)
      @mouseUpInside = true
    else
      @mouseUpInside = false

    return if !@mouseDownInside
    return if !@mouseUpInside
    return if !@isActive
    @toggleHighlightAtSelection(@content, @article_id)

  updateSelectedArticle: (e) =>
    @content    = $(e.currentTarget).closest('.textBubble-content')
    @article_id = @content.data('id')
    return true if @article_id
    @content    = $(e.currentTarget)
    @article_id = @content.data('id')
    return true if @article_id
    false

  #
  # toggle Highlight
  # ================
  #
  # - only works when the selection starts and ends inside an article
  # - clears highlights in selection
  # - or highlights the selection
  # - clears the selection

  toggleHighlightAtSelection: (article, article_id) =>
    selection = rangy.getSelection()

    # activate selection background
    article.attr('data-highlightcolor', @colors[@activeColorIndex].name)

    if @highlighter.selectionOverlapsHighlight selection
      @highlighter.unhighlightSelection()
      selection.removeAllRanges()
      @highlightDisable()
      @storeHighlights(article_id)
      return

    if selection && selection.rangeCount > 0
      @highlighter.highlightSelection @highlightClass,
        selection: selection
        containerElementId: article.get(0).id
      selection.removeAllRanges()
      @highlightDisable()
      @storeHighlights(article_id)
