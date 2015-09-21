class App.TicketZoomArticleView extends App.Controller
  constructor: ->
    super

    @article_controller = {}

  execute: (params) ->
    all = []
    for ticket_article_id in params.ticket_article_ids
      if !@article_controller[ticket_article_id]
        el = $('<div></div>')
        @article_controller[ticket_article_id] = new ArticleViewItem(
          ticket:            @ticket
          ticket_article_id: ticket_article_id
          el:                el
          ui:                @ui
        )
        all.push el
    @el.append( all )

class ArticleViewItem extends App.Controller
  hasChangedAttributes: ['from', 'to', 'cc', 'subject', 'body', 'internal']

  elements:
    '.textBubble-content':           'textBubbleContent'
    '.textBubble-overflowContainer': 'textBubbleOverflowContainer'

  events:
    'click .show_toogle':          'show_toogle'
    'click .textBubble':           'toggle_meta_with_delay'
    'click .textBubble a':         'stopPropagation'
    'click .js-unfold':            'unfold'

  constructor: ->
    super

    @seeMore = false

    @render()

    # set expand of text area only once
    @bind(
      'ui::ticket::shown'
      (data) =>
        if !@shown
          if data.ticket_id.toString() is @ticket.id.toString()
            @setSeeMore()
            @shown = true
    )

    # subscribe to changes
    @subscribeId = App.TicketArticle.full(@ticket_article_id, @render, false, true)

  release: =>
    App.TicketArticle.unsubscribe(@subscribeId)

  hasChanged: (article) =>

    # if no last article exists, remember it and return true
    if !@article_last_updated
      @article_last_updated = {}
      for item in @hasChangedAttributes
        @article_last_updated[item] = article[item]
      return true

    # compare last and current article attributes
    article_last_updated_check = {}
    for item in @hasChangedAttributes
      article_last_updated_check[item] = article[item]
    diff = difference(@article_last_updated, article_last_updated_check)
    return false if !diff || _.isEmpty( diff )
    @article_last_updated = article_last_updated_check
    true

  render: (article) =>

    # get articles
    @article = App.TicketArticle.fullLocal( @ticket_article_id )

    # set @el attributes
    @el.addClass("ticket-article-item #{@article.sender.name.toLowerCase()}")
    if @article.internal is true
      @el.addClass('is-internal')
    else
      @el.removeClass('is-internal')
    @el.attr('data-id',  @article.id)
    @el.attr('id', "article-#{@article.id}")

    # check if rerender is needed
    return if !@hasChanged(@article)

    # prepare html body
    if @article.content_type is 'text/html'
      @article['html'] = @article.body
    else
      @article['html'] = App.Utils.textCleanup( @article.body )
      @article['html'] = App.Utils.text2html( @article.body )

    @html App.view('ticket_zoom/article_view')(
      ticket:     @ticket
      article:    @article
      isCustomer: @isRole('Customer')
    )

    new App.WidgetAvatar(
      el:      @$('.js-avatar')
      user_id: @article.created_by_id
      size:    40
    )

    new App.TicketZoomArticleActions(
      el:      @$('.js-article-actions')
      ticket:  @ticket
      article: @article
    )

    # set see more option
    @setSeeMore()

  # set see more options
  setSeeMore: =>
    maxHeight               = 560
    bubbleContent           = @textBubbleContent
    bubbleOvervlowContainer = @textBubbleOverflowContainer

    # expand if see more is already clicked
    if @seeMore
      bubbleContent.css('height', 'auto')
      bubbleOvervlowContainer.addClass('hide')
      return

    # reset bubble heigth and "see more" opacity
    bubbleContent.css('height', '')
    bubbleOvervlowContainer.css('opacity', '')

    # remember offset of "see more"
    offsetTop = bubbleContent.find('.js-signatureMarker').position()

    # remember bubble heigth
    heigth = bubbleContent.height()
    if offsetTop && heigth
      bubbleContent.attr('data-height', heigth)
      bubbleContent.css('height', "#{offsetTop.top + 30}px")
      bubbleOvervlowContainer.removeClass('hide')
    else if heigth > maxHeight
      bubbleContent.attr('data-height', heigth)
      bubbleContent.css('height', "#{maxHeight}px")
      bubbleOvervlowContainer.removeClass('hide')
    else
      bubbleOvervlowContainer.addClass('hide')

  show_toogle: (e) ->
    e.stopPropagation()
    e.preventDefault()
    #$(e.target).hide()
    if $(e.target).next('div')[0]
      if $(e.target).next('div').hasClass('hide')
        $(e.target).next('div').removeClass('hide')
        $(e.target).text( App.i18n.translateContent('Fold in') )
      else
        $(e.target).text( App.i18n.translateContent('See more') )
        $(e.target).next('div').addClass('hide')

  stopPropagation: (e) ->
    e.stopPropagation()

  toggle_meta_with_delay: (e) =>
    # allow double click select
    # by adding a delay to the toggle

    if @lastClick and +new Date - @lastClick < 150
      clearTimeout(@toggleMetaTimeout)
    else
      @toggleMetaTimeout = setTimeout(@toggle_meta, 150, e)
      @lastClick = +new Date

  toggle_meta: (e) =>
    e.preventDefault()

    animSpeed      = 300
    article        = $(e.target).closest('.ticket-article-item')
    metaTopClip    = article.find('.article-meta-clip.top')
    metaBottomClip = article.find('.article-meta-clip.bottom')
    metaTop        = article.find('.article-content-meta.top')
    metaBottom     = article.find('.article-content-meta.bottom')

    if @elementContainsSelection( article.get(0) )
      @stopPropagation(e)
      return false

    if !metaTop.hasClass('hide')
      article.removeClass('state--folde-out')

      # scroll back up
      article.velocity "scroll",
        container: article.scrollParent()
        offset: -article.offset().top - metaTop.outerHeight()
        duration: animSpeed
        easing: 'easeOutQuad'

      metaTop.velocity
        properties:
          translateY: 0
          opacity: [ 0, 1 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'
          complete: -> metaTop.addClass('hide')

      metaBottom.velocity
        properties:
          translateY: [ -metaBottom.outerHeight(), 0 ]
          opacity: [ 0, 1 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'
          complete: -> metaBottom.addClass('hide')

      metaTopClip.velocity({ height: 0 }, animSpeed, 'easeOutQuad')
      metaBottomClip.velocity({ height: 0 }, animSpeed, 'easeOutQuad')
    else
      article.addClass('state--folde-out')
      metaBottom.removeClass('hide')
      metaTop.removeClass('hide')

      # balance out the top meta height by scrolling down
      article.velocity("scroll",
        container: article.scrollParent()
        offset: -article.offset().top + metaTop.outerHeight()
        duration: animSpeed
        easing: 'easeOutQuad'
      )

      metaTop.velocity
        properties:
          translateY: [ 0, metaTop.outerHeight() ]
          opacity: [ 1, 0 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'

      metaBottom.velocity
        properties:
          translateY: [ 0, -metaBottom.outerHeight() ]
          opacity: [ 1, 0 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'

      metaTopClip.velocity({ height: metaTop.outerHeight() }, animSpeed, 'easeOutQuad')
      metaBottomClip.velocity({ height: metaBottom.outerHeight() }, animSpeed, 'easeOutQuad')

  unfold: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @seeMore = true

    bubbleContent           = @textBubbleContent
    bubbleOvervlowContainer = @textBubbleOverflowContainer

    bubbleOvervlowContainer.velocity
      properties:
        opacity: 0
      options:
        duration: 300

    bubbleContent.velocity
      properties:
        height: bubbleContent.attr('data-height')
      options:
        duration: 300
        complete: -> bubbleOvervlowContainer.addClass('hide')

  isOrContains: (node, container) ->
    while node
      if node is container
        return true
      node = node.parentNode
    false

  elementContainsSelection: (el) ->
    sel = window.getSelection()
    if sel.rangeCount > 0 && sel.toString()
      for i in [0..sel.rangeCount-1]
        if !@isOrContains(sel.getRangeAt(i).commonAncestorContainer, el)
          return false
      return true
    false
