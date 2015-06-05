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

    #@articles = @el.closest('.content').find('.textBubble-content')

    rangy.init()

    @highlighter = rangy.createHighlighter(document, 'TextRange')
    @addClassApplier entry for entry in @colors

    @setColor()
    @render()

    # store original highlight css data
    @storeOriginalHighlight()

    update = =>
      @loadHighlights()
      @refreshObserver()
    App.Delay.set( update, 800 )

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
    console.log('refreshObserver', articles)
    articles.off('mouseup', @onMouseUp)
    articles.on('mouseup', @onMouseUp) #future: touchend

  # for testing purposes the highlights get stored in localStorage
  loadHighlights: ->
    @el.closest('.content').find('.textBubble-content').each( (index, element) =>
      article_id = $(element).data('id')
      article    = App.TicketArticle.find(article_id)
      if article.preferences && article.preferences['highlight']
        console.log('highlight', article.preferences['highlight'])
        @highlighter.deserialize(article.preferences['highlight'])
    )

  # the serialization creates one string for the entiery ticket
  # containing the offsets and the highlight classes
  #
  # we have to check how it works with having open several tickets – it might break
  #
  # if classes can be changed in the admin interface
  # we have to watch out to not end up with empty highlight classes
  storeHighlights: (article_id) ->
    article                          = App.TicketArticle.find(article_id)
    data                             = @highlighter.serialize()
    console.log('HI', article_id, data)
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
    console.log('toggleHighlight', @isActive)

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
    # TODO: @mrflix - still needed?
    #@$('.js-highlightColor .visibility-change.active').removeClass('active')
    #$(e.currentTarget).find('.visibility-change').addClass('active')

    @activeColorIndex = $(e.currentTarget).attr('data-key')
    @setColor()

    @highlightEnable()

    # check if selection exists - highlight it or remove highlight
    @toggleHighlightAtSelection(@content, @article_id)

  onMouseUp: (e) =>
    @updateSelectedArticle(e)

    console.log('onMouseUp', @isActive, @content, @article_id)
    if @isActive
      @toggleHighlightAtSelection(@content, @article_id) # @articles.selector

  updateSelectedArticle: (e) =>
    @content    = $(e.currentTarget).closest('.textBubble-content')
    @article_id = @content.data('id')
    if !@article_id
      @content    = $(e.currentTarget)
      @article_id = @content.data('id')

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
      console.log('SELECTION EXISTS, REMOVED IT')
      @highlighter.unhighlightSelection()
    else
      console.log('NEW SELECTION')
      @highlighter.highlightSelection @highlightClass,
        selection: selection
        containerElementId: article.get(0).id

    # remove selection
    selection.removeAllRanges()

    @highlightDisable()

    # save new selections
    @storeHighlights(article_id)