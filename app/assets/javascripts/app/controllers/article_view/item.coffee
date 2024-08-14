class App.ArticleViewItem extends App.ControllerObserver
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
    'click .article-meta-permanent':             'toggleMetaWithDelay'
    'click .textBubble':                         'toggleMetaWithDelay'
    'click .textBubble a':                       'stopPropagation'
    'click .js-toggleFold':                      'toggleFold'
    'click .richtext-content img':               'imageView'
    'click .attachments img':                    'imageView'
    'click .file-calendar .js-preview':          'calendarView'
    'click .js-securityRetryProcess':            'retrySecurityProcess'
    'click .js-retryWhatsAppAttachmentDownload': 'retryWhatsAppAttachmentDownload'
    'click .js-fetchOriginalFormatting':         'fetchOriginalFormatting'

  @SEE_MORE_MIN_HEIGHT: 90
  @SEE_MORE_MAX_HEIGHT: 560

  constructor: ->
    super
    @seeMoreOpen = false

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
    #@highlighter.loadHighlights(@object_id)
    d = =>
      if @highlighter
        @highlighter.loadHighlights(@object_id)
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

    # check if email link needs to be updated
    links = clone(article.preferences.links) || []
    if article.type.name is 'email'
      link =
        name: __('Raw')
        url: "#{@Config.get('api_path')}/ticket_article_plain/#{article.id}"
        target: '_blank'
      links.push link

    # attachments prepare
    attachments = App.TicketArticle.contentAttachments(article)
    if article.attachments
      for attachment in article.attachments

        dispositionParams = ''
        if attachment?.preferences['Content-Type'] isnt 'text/html'
          dispositionParams = '?disposition=attachment'

        attachment.url = "#{App.Config.get('api_path')}/ticket_attachment/#{article.ticket_id}/#{article.id}/#{attachment.id}#{dispositionParams}"
        attachment.preview_url = "#{App.Config.get('api_path')}/ticket_attachment/#{article.ticket_id}/#{article.id}/#{attachment.id}?view=preview"

        if attachment && attachment.preferences && attachment.preferences['original-format'] is true
          @originalFormattingURL = "#{App.Config.get('api_path')}/ticket_attachment/#{article.ticket_id}/#{article.id}/#{attachment.id}?disposition=attachment"
          link =
              url: @originalFormattingURL
              name: __('Original Formatting')
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

    if article.preferences?.whatsapp
      icon = null
      msg  = null
      if article.preferences?.whatsapp?.timestamp_read
        icon = 'double-checkmark'
        msg  = __('read by the customer')
      else if article.preferences?.whatsapp?.timestamp_delivered
        icon = 'double-checkmark-outline'
        msg  = __('delivered to the customer')
      else if article.preferences?.whatsapp?.timestamp_sent
        icon = 'checkmark-outline'
        msg  = __('sent to the customer')

      article['delivery_status_icon']    = icon
      article['delivery_status_message'] = msg

    @html App.view('ticket_zoom/article_view')(
      ticket:      @ticket
      article:     article
      attachments: App.view('generic/attachments')(attachments: attachments, has_body: !!article.html)
      links:       links
    )

    new App.WidgetAvatar(
      el:        @$('.js-avatar')
      object_id: article.origin_by_id || article.created_by_id
      size:      40
    )

    @articleActions = new App.TicketZoomArticleActions(
      el:             @$('.js-article-actions')
      ticket:         @ticket
      article:        article
      lastAttributes: @lastAttributes
      form_id:        @form_id
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
    maxHeight               = @constructor.SEE_MORE_MAX_HEIGHT
    minHeight               = @constructor.SEE_MORE_MIN_HEIGHT
    bubbleContent           = @textBubbleContent
    bubbleOverflowContainer = @textBubbleOverflowContainer

    # expand if see more is already clicked
    if @seeMoreOpen
      bubbleContent.css('height', 'auto')
    else
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
    bubbleContentHeight = bubbleContent.height()

    # get marker height
    if offsetTop
      markerHeight = offsetTop.top

    # if signature marker exists and height is within maxHeight
    if markerHeight && markerHeight < maxHeight
      newHeight = markerHeight + 30
      if newHeight < minHeight
        newHeight = minHeight

      bubbleContent.attr('data-height', bubbleContentHeight + 30)
      bubbleContent.attr('data-height-origin', newHeight)
      bubbleContent.css('height', "#{newHeight}px")
      bubbleOverflowContainer.removeClass('hide')

    # if height is higher then maxHeight
    else if bubbleContentHeight > maxHeight
      bubbleContent.attr('data-height', bubbleContentHeight + 30)
      bubbleContent.attr('data-height-origin', maxHeight)
      newHeight = if @seeMoreOpen then 'auto' else "#{maxHeight}px"
      bubbleContent.css('height', newHeight)
      bubbleOverflowContainer.toggleClass('is-open', @seeMoreOpen).find('.js-toggleFold').html(@label)
      bubbleOverflowContainer.removeClass('hide')
    else
      bubbleOverflowContainer.addClass('hide')

  retrySecurityProcess: (e) ->
    e.preventDefault()
    e.stopPropagation()

    article_id = $(e.target).closest('.ticket-article-item').data('id')
    article    = App.TicketArticle.find(article_id)

    @ajax(
      id:   'retrySecurityProcess'
      type: 'POST'
      url:  "#{@apiPath}/ticket_articles/#{article_id}/retry_security_process"
      processData: true
      success: (encryption_data, status, xhr) =>
        for data in encryption_data
          continue if article.preferences.security.type isnt data.type

          if data.sign.success
            @notify
              type: 'success'
              msg: __('The signature was successfully verified.')
          else if data.sign.comment
            comment = App.i18n.translateContent('Signature verification failed!') + ' ' + App.i18n.translateContent(data.sign.comment || '', data.sign.commentPlaceholders)
            @notify
              type: 'error'
              msg: comment
              timeout: 2000

          if data.encryption.success
            @notify
              type: 'success'
              msg:  __('Decryption was successful.')
          else if data.encryption.comment
            comment = App.i18n.translateContent('Decryption failed!') + ' ' + App.i18n.translateContent(data.encryption.comment || '', data.encryption.commentPlaceholders)
            @notify
              type: 'error'
              msg:  comment
              timeout: 2000

      error: (xhr) =>
        @notify
          type: 'error'
          msg:  __('The retried security process failed!')
    )

  retryWhatsAppAttachmentDownload: (e) ->
    e.preventDefault()
    e.stopPropagation()

    article_id = $(e.target).closest('.ticket-article-item').data('id')

    @ajax(
      id:   'retryWhatsAppAttachmentDownload'
      type: 'POST'
      url:  "#{@apiPath}/ticket_articles/#{article_id}/retry_whatsapp_attachment_download"
      processData: true
      success: (data, status, xhr) =>
        @notify
          type: 'success'
          msg:  __('Downloading attachments…')

      error: (data, status, xhr) =>
        details = data.responseJSON || {}
        @notify
          type: 'error'
          msg:  details.error
    )

  fetchOriginalFormatting: (e) ->
    return if not @originalFormattingURL

    e.preventDefault()
    e.stopPropagation()

    originalFormattingLink = document.createElement('a')
    originalFormattingLink.href = @originalFormattingURL
    originalFormattingLink.target = '_blank'
    originalFormattingLink.click()
    originalFormattingLink.remove()

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
      @label = App.i18n.translateContent('See more')
      height = bubbleContent.attr('data-height-origin')
      @seeMoreOpen = false
    else
      @label = App.i18n.translateContent('See less')
      height = bubbleContent.attr('data-height')
      @seeMoreOpen = true

    bubbleOverflowContainer.toggleClass('is-open', @seeMoreOpen).find('.js-toggleFold').html(@label)

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
    # take care of images surrounded by a link
    if e.target && e.target.parentNode && e.target.parentNode.nodeName.toLowerCase() == 'a'
      return false

    e.preventDefault()
    e.stopPropagation()
    new App.TicketZoomArticleImageView(image: $(e.target).get(0).outerHTML, parentElement: $(e.currentTarget))

  calendarView: (e) ->
    e.preventDefault()
    e.stopPropagation()
    parentElement = $(e.target).closest('.attachment.file-calendar')
    new App.TicketZoomArticleCalendarView(calendar: parentElement.get(0).outerHTML)

  updateFormId: (newFormId) ->
    @articleActions?.form_id = newFormId
