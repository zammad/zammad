class App.TicketZoomArticleView extends App.Controller
  constructor: ->
    super
    @articleController = {}
    @run()

  execute: (params) =>
    @ticket_article_ids = params.ticket_article_ids
    @run()

  run: =>
    all = []
    for ticket_article_id, index in @ticket_article_ids
      controllerKey = ticket_article_id.toString()
      if !@articleController[controllerKey]
        el = $('<div></div>')
        @articleController[controllerKey] = new ArticleViewItem(
          ticket:     @ticket
          object_id:  ticket_article_id
          el:         el
          ui:         @ui
          highligher: @highligher
          form_id:    @form_id
        )
        if !@ticketArticleInsertByIndex(index, el)
          all.push el
    @el.append(all)

    # check elements to remove
    for article_id, controller of @articleController
      exists = false
      for localArticleId in @ticket_article_ids
        if localArticleId.toString() is article_id.toString()
          exists = true
      if !exists
        controller.remove()
        delete @articleController[article_id.toString()]

  ticketArticleInsertByIndex: (elIndex, el) =>
    return false if !@$('.ticket-article-item').length

    # in case of a merge it can happen that there are already
    # articles rendered in the ticket, but the new article need
    # to be inserted at the correct position in the the ticket
    for index in [elIndex .. 0]
      article_id = @ticket_article_ids[index]
      continue if !article_id
      article = @$(".ticket-article-item[data-id=#{article_id}]")
      continue if !article.length
      article.after(el)
      return true

    for index in [elIndex .. @ticket_article_ids.length - 1]
      article_id = @ticket_article_ids[index]
      continue if !article_id
      article = @$(".ticket-article-item[data-id=#{article_id}]")
      continue if !article.length
      article.before(el)
      return true

    false

  updateFormId: (newFormId) ->
    @form_id = newFormId

    for id, viewItem of @articleController
      viewItem.updateFormId(newFormId)

class ArticleViewItem extends App.ControllerObserver
  model: 'TicketArticle'
  observe:
    from: true
    to: true
    cc: true
    subject: true
    body: true
    internal: true
    preferences: true

  elements:
    '.textBubble-content':           'textBubbleContent'
    '.textBubble-content img':       'textBubbleImages'
    '.textBubble-overflowContainer': 'textBubbleOverflowContainer'

  events:
    'click .article-meta-permanent':  'toggleMetaWithDelay'
    'click .textBubble':              'toggleMetaWithDelay'
    'click .textBubble a':            'stopPropagation'
    'click .js-toggleFold':           'toggleFold'
    'click .richtext-content img':    'imageView'
    'click .attachments img':         'imageView'
    'click .js-securityRetryProcess': 'retrySecurityProcess'

  constructor: ->
    super
    @seeMore = false

    # set expand of text area only once
    @controllerBind('ui::ticket::shown', (data) =>
      return if data.ticket_id.toString() isnt @ticket.id.toString()

      # set highlighter
      @setHighlighter()

      # set see more
      @setSeeMore()
    )

  setHighlighter: =>
    return if @el.is(':hidden')
    # use delay do no ui blocking
    #@highligher.loadHighlights(@object_id)
    d = =>
      @highligher.loadHighlights(@object_id)
    @delay(d, 200)

  render: (article) =>

    # set @el attributes
    @el.addClass("ticket-article-item #{article.sender.name.toLowerCase()}")
    @el.attr('data-id', article.id)
    @el.attr('id', "article-#{article.id}")
    if article.internal
      @el.addClass('is-internal')
    else
      @el.removeClass('is-internal')

    # check if email link need to be updated
    links = clone(article.preferences.links) || []
    if article.type.name is 'email'
      link =
        name: 'Raw'
        url: "#{@Config.get('api_path')}/ticket_article_plain/#{article.id}"
        target: '_blank'
      links.push link

    # attachments prepare
    attachments = App.TicketArticle.contentAttachments(article)
    if article.attachments
      for attachment in article.attachments

        dispositionParams = ''
        if attachment?.preferences['Content-Type'] isnt 'application/pdf' && attachment?.preferences['Content-Type'] isnt 'text/html'
          dispositionParams = '?disposition=attachment'

        attachment.url = "#{App.Config.get('api_path')}/ticket_attachment/#{article.ticket_id}/#{article.id}/#{attachment.id}#{dispositionParams}"
        attachment.preview_url = "#{App.Config.get('api_path')}/ticket_attachment/#{article.ticket_id}/#{article.id}/#{attachment.id}?view=preview"

        if attachment && attachment.preferences && attachment.preferences['original-format'] is true
          link =
              url: "#{App.Config.get('api_path')}/ticket_attachment/#{article.ticket_id}/#{article.id}/#{attachment.id}?disposition=attachment"
              name: 'Original Formatting'
              target: '_blank'
          links.push link

    # prepare html body
    if article.content_type is 'text/html'
      body = article.body
      if article.preferences && article.preferences.signature_detection
        signatureDetected = '<span class="js-signatureMarker"></span>'
        body = body.replace(signatureDetected, '')
        body = body.split('<br>')
        body.splice(article.preferences.signature_detection, 0, signatureDetected)
        body = body.join('<br>')
      else
        body = App.Utils.signatureIdentifyByHtml(body)
      article['html'] = body
    else

      # client signature detection
      bodyHtml = App.Utils.text2html(article.body)
      article['html'] = App.Utils.signatureIdentifyByPlaintext(bodyHtml)

      # if no signature detected or within first 25 lines, check if signature got detected in backend
      if article['html'] is bodyHtml || (article.preferences && article.preferences.signature_detection < 25)
        signatureDetected = false
        body = article.body
        if article.preferences && article.preferences.signature_detection
          signatureDetected = '########SIGNATURE########'
          # coffeelint: disable=no_unnecessary_double_quotes
          body = body.split("\n")
          body.splice(article.preferences.signature_detection, 0, signatureDetected)
          body = body.join("\n")
          # coffeelint: enable=no_unnecessary_double_quotes
        if signatureDetected
          body = App.Utils.textCleanup(body)
          article['html'] = App.Utils.text2html(body)
          article['html'] = article['html'].replace(signatureDetected, '<span class="js-signatureMarker"></span>')

    if article.preferences.delivery_message
      @html App.view('ticket_zoom/article_view_delivery_failed')(
        ticket:      @ticket
        article:     article
        attachments: attachments
        links:       links
      )
      return
    if article.sender.name is 'System' && article.type.name isnt 'note'
    #if article.sender.name is 'System' && article.preferences.perform_origin is 'trigger'
      @html App.view('ticket_zoom/article_view_system')(
        ticket:      @ticket
        article:     article
        attachments: attachments
        links:       links
      )
      return
    @html App.view('ticket_zoom/article_view')(
      ticket:      @ticket
      article:     article
      attachments: App.view('generic/attachments')(attachments: attachments)
      links:       links
    )

    new App.WidgetAvatar(
      el:        @$('.js-avatar')
      object_id: article.origin_by_id || article.created_by_id
      size:      40
    )

    @articleActions = new App.TicketZoomArticleActions(
      el:              @$('.js-article-actions')
      ticket:          @ticket
      article:         article
      lastAttributres: @lastAttributres
      form_id:         @form_id
    )

    # set see more
    @shown = false
    a = =>
      @setSeeMore()
    @delay(a, 50)

    # set highlighter
    @setHighlighter()

  # set see more options
  setSeeMore: =>
    return if @el.is(':hidden')
    return if @shown
    @shown = true

    @textBubbleImages.each (i, el) =>
      if !el.complete
        $(el).one 'load', @measureSeeMore

    @measureSeeMore()

  measureSeeMore: =>
    maxHeight               = 560
    minHeight               = 90
    bubbleContent           = @textBubbleContent
    bubbleOverflowContainer = @textBubbleOverflowContainer

    # expand if see more is already clicked
    if @seeMore
      bubbleContent.css('height', 'auto')
      return

    # reset bubble height and "see more" opacity
    bubbleContent.css('height', '')
    bubbleOverflowContainer.css('opacity', '')

    # remember offset of "see more"
    signatureMarker = bubbleContent.find('.js-signatureMarker')
    if !signatureMarker.get(0)
      signatureMarker = bubbleContent.find('div [data-signature=true]')
    offsetTop = signatureMarker.position()

    # safari - workaround
    # in safari sometimes the marker is directly on top via .top and inspector but it isn't
    # in this case use the next element
    if offsetTop && offsetTop.top is 0
      offsetTop = signatureMarker.next('div, p, br').position()

    # remember bubble content height
    bubbleContentHeigth = bubbleContent.height()

    # get marker height
    if offsetTop
      markerHeight = offsetTop.top

    # if signature marker exists and height is within maxHeight
    if markerHeight && markerHeight < maxHeight
      newHeigth = markerHeight + 30
      if newHeigth < minHeight
        newHeigth = minHeight

      bubbleContent.attr('data-height', bubbleContentHeigth + 30)
      bubbleContent.attr('data-height-origin', newHeigth)
      bubbleContent.css('height', "#{newHeigth}px")
      bubbleOverflowContainer.removeClass('hide')

    # if height is higher then maxHeight
    else if bubbleContentHeigth > maxHeight
      bubbleContent.attr('data-height', bubbleContentHeigth + 30)
      bubbleContent.attr('data-height-origin', maxHeight)
      bubbleContent.css('height', "#{maxHeight}px")
      bubbleOverflowContainer.removeClass('hide')
    else
      bubbleOverflowContainer.addClass('hide')

  retrySecurityProcess: (e) ->
    e.preventDefault()
    e.stopPropagation()

    article_id = $(e.target).closest('.ticket-article-item').data('id')

    @ajax(
      id:   'retrySecurityProcess'
      type: 'POST'
      url:  "#{@apiPath}/ticket_articles/#{article_id}/retry_security_process"
      processData: true
      success: (data, status, xhr) =>
        if data.sign.success
          @notify
            type: 'success'
            msg:  App.i18n.translateContent('Verify sign success!')
        else if data.sign.comment
          comment = App.i18n.translateContent('Verify sign failed!') + ' ' + App.i18n.translateContent(data.sign.comment || '')
          @notify
            type: 'error'
            msg: comment
            timeout: 2000

        if data.encryption.success
          @notify
            type: 'success'
            msg:  App.i18n.translateContent('Decryption success!')
        else if data.encryption.comment
          comment = App.i18n.translateContent('Decryption failed!') + ' ' + App.i18n.translateContent(data.encryption.comment || '')
          @notify
            type: 'error'
            msg:  comment
            timeout: 2000

      error: (xhr) =>
        @notify
          type: 'error'
          msg:  App.i18n.translateContent('Retry security process failed!')
    )

  stopPropagation: (e) ->
    e.stopPropagation()

  toggleMetaWithDelay: (e) =>
    # allow double click select
    # by adding a delay to the toggle
    delay = 300

    article = $(e.target).closest('.ticket-article-item')
    if @elementContainsSelection(article.get(0))
      @stopPropagation(e)
      return false

    if @lastClick and +new Date - @lastClick < delay
      clearTimeout(@toggleMetaTimeout)
    else
      @toggleMetaTimeout = setTimeout(@toggleMeta, delay, e)
      @lastClick = +new Date

  toggleMeta: (e) =>
    e.preventDefault()

    animSpeed      = 300
    article        = $(e.target).closest('.ticket-article-item')
    metaTopClip    = article.find('.article-meta-clip.top')
    metaBottomClip = article.find('.article-meta-clip.bottom')
    metaTop        = article.find('.article-content-meta.top')
    metaBottom     = article.find('.article-content-meta.bottom')

    if @elementContainsSelection(article.get(0))
      @stopPropagation(e)
      return false

    if !metaTop.hasClass('hide')
      article.removeClass('state--folde-out')

      # scroll back up
      article.velocity 'scroll',
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
      article.velocity('scroll',
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

  toggleFold: (e) ->
    e.preventDefault()
    e.stopPropagation()

    bubbleContent           = @textBubbleContent
    bubbleOverflowContainer = @textBubbleOverflowContainer

    if @seeMoreOpen
      label = App.i18n.translateContent('See more')
      height = bubbleContent.attr('data-height-origin')
      @seeMoreOpen = false
    else
      label = App.i18n.translateContent('See less')
      height = bubbleContent.attr('data-height')
      @seeMoreOpen = true

    bubbleOverflowContainer.toggleClass('is-open', @seeMoreOpen).find('.js-toggleFold').html(label)

    bubbleContent.velocity
      properties:
        height: height
      options:
        duration: 300

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

  remove: =>
    @el.remove()

  imageView: (e) ->
    e.preventDefault()
    e.stopPropagation()
    new App.TicketZoomArticleImageView(image: $(e.target).get(0).outerHTML, parentElement: $(e.currentTarget))

  updateFormId: (newFormId) ->
    @articleActions?.form_id = newFormId
