class App.TicketZoomHighlighter extends App.Controller
  elements:
    '.textBubble-content': 'articles'
    '.js-highlight .marker-icon': 'highlighterControl'

  events:
    'click .js-highlight': 'toggleHighlight'
    'click .js-highlightColor': 'pickColor'

  colors: [
    {
      name: 'Yellow'
      color: "#f7e7b2"
    },
    {
      name: 'Green'
      color: "#bce7b6"
    },
    {
      name: 'Blue'
      color: "#b3ddf9"
    },
    {
      name: 'Pink'
      color: "#fea9c5"
    },
    {
      name: 'Purple'
      color: "#eac5ee"
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

    @loadHighlights()

  render: ->
    @html App.view('ticket_zoom/highlighter')
      colors: @colors
      activeColorIndex: @activeColorIndex

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

  highlightDisable: =>
    @isActive = false
    @restoreOriginalHighlight()
    #@highlighterControl.css('opacity', @originalHighlight.opacity)

  active: =>
    @isActive

  # for testing purposes the highlights get stored in localStorage
  loadHighlights: ->
    if highlights = localStorage['highlights']
      @highlighter.deserialize localStorage['highlights']

  # the serialization creates one string for the entiery ticket
  # containing the offsets and the highlight classes
  #
  # we have to check how it works with having open several tickets – it might break
  #
  # if classes can be changed in the admin interface
  # we have to watch out to not end up with empty highlight classes
  storeHighlights: ->
    localStorage['highlights'] = @highlighter.serialize()

  # the colors is set via css classes (can't do it inline with rangy)
  # thus we have to create a stylesheet if the colors
  # can be changed in the admin interface
  addClassApplier: (entry) ->
    @highlighter.addClassApplier rangy.createCssClassApplier(@highlightClassPrefix + entry.name)

  setColor: ->
    @highlightClass = @highlightClassPrefix + @colors[@activeColorIndex].name

    if @isActive
      @articles.attr('data-highlightcolor', @colors[@activeColorIndex].name)

  toggleHighlight: (e) =>
    if @isActive
      @restoreOriginalHighlight()
    else
      @highlightEnable()
    return

    console.log('toggleHighlight', @isActive, @articles)
    if @isActive
      $(e.currentTarget).removeClass('active')
      @isActive = false
      @articles.off('mouseup', @onMouseUp)
      @articles.removeAttr('data-highlightcolor')
    else
      selection = rangy.getSelection()
      # if there's already something selected,
      # don't go into highlight mode
      # just toggle the selected
      if !selection.isCollapsed
        @toggleHighlightAtSelection $(selection.anchorNode).closest @articles.selector
      else
        # toggle ui
        $(e.currentTarget).addClass('active')

        # activate selection background
        @articles.attr('data-highlightcolor', @colors[@activeColorIndex].name)

        @isActive = true
        @articles.on('mouseup', @onMouseUp) #future: touchend

  pickColor: (e) =>
    @$('.js-highlightColor .visibility-change.active').removeClass('active')
    $(e.currentTarget).find('.visibility-change').addClass('active')
    @activeColorIndex =  $(e.currentTarget).attr('data-key')


    @isActive = true
    console.log('ooo', @activeColorIndex, @colors[@activeColorIndex].color, @colors[@activeColorIndex])
    @highlighterControl.css('fill', @colors[@activeColorIndex].color)
    @highlighterControl.css('opacity', 1)
    @setColor()

  onMouseUp: (e) =>
    #@toggleHighlightAtSelection $(e.currentTarget).closest('.textBubble-content')# @articles.selector

  #
  # toggle Highlight
  # ================
  #
  # - only works when the selection starts and ends inside an article
  # - clears highlights in selection
  # - or highlights the selection
  # - clears the selection

  toggleHighlightAtSelection: (article) =>
    selection = rangy.getSelection()

    if @highlighter.selectionOverlapsHighlight selection
      @highlighter.unhighlightSelection()
    else
      @highlighter.highlightSelection @highlightClass,
        selection: selection
        containerElementId: article.get(0).id

    # remove selection
    selection.removeAllRanges()

    @highlightDisable()


    #@storeHighlights()