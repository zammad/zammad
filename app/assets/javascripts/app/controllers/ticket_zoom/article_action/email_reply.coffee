class EmailReply extends App.Controller
  @action: (actions, ticket, article, ui) ->
    return actions if !ticket.editable()
    return actions if ticket.currentView() is 'customer'
    group = ticket.group
    return actions if !group.email_address_id

    if article.type.name is 'email' || article.type.name is 'web'
      actions.push {
        name: __('reply')
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }

      # check if reply all needs to be shown
      recipients = []
      if article.sender.name is 'Customer'
        if article.from
          localRecipients = emailAddresses.parseAddressList(article.from)
          if localRecipients
            recipients = recipients.concat localRecipients
      if article.to
        localRecipients = emailAddresses.parseAddressList(article.to)
        if localRecipients
          recipients = recipients.concat localRecipients
      if article.cc
        localRecipients = emailAddresses.parseAddressList(article.cc)
        if localRecipients
          recipients = recipients.concat localRecipients

      # remove system addresses
      localAddresses = App.EmailAddress.all()
      foreignRecipients = []
      recipientUsed = {}
      for recipient in recipients
        if !_.isEmpty(recipient.address)
          localRecipientAddress = recipient.address.toString().toLowerCase()

          if !recipientUsed[localRecipientAddress]
            recipientUsed[localRecipientAddress] = true
            localAddress = false
            for address in localAddresses
              if localRecipientAddress is address.email.toString().toLowerCase()
                recipientUsed[localRecipientAddress] = true
                localAddress = true
            if !localAddress
              foreignRecipients.push recipient

      # check if reply all is needed
      if foreignRecipients.length > 1
        actions.push {
          name: __('reply all')
          type: 'emailReplyAll'
          icon: 'reply-all'
          href: '#'
        }

      # always show forward
      actions.push {
        name: __('forward')
        type: 'emailForward'
        icon: 'forward'
        href: '#'
      }

    if article.sender.name is 'Customer' && article.type.name is 'phone'
      actions.push {
        name: __('reply')
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
      actions.push {
        name: __('forward')
        type: 'emailForward'
        icon: 'forward'
        href: '#'
      }
    if article.sender.name is 'Agent' && article.type.name is 'phone'
      actions.push {
        name: __('reply')
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
      actions.push {
        name: __('forward')
        type: 'emailForward'
        icon: 'forward'
        href: '#'
      }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'emailReply' && type isnt 'emailReplyAll' && type isnt 'emailForward'

    if type is 'emailReply'
      @emailReply(false, ticket, article, ui)

    else if type is 'emailReplyAll'
      @emailReply(true, ticket, article, ui)

    else if type is 'emailForward'
      @emailForward(ticket, article, ui)

    true

  @emailReply: (all = false, ticket, article, ui) ->

    # get reference article
    type               = App.TicketArticleType.find(article.type_id)
    article_created_by = App.User.find(article.created_by_id)
    email_addresses    = App.EmailAddress.all()

    ui.scrollToCompose()

    # empty form
    articleNew = App.Utils.getRecipientArticle(ticket, article, article_created_by, type, email_addresses, all)

    if ui.Config.get('ui_ticket_zoom_article_email_subject')
      if _.isEmpty(article.subject)
        articleNew.subject = ticket.title
      else
        articleNew.subject = article.subject

    # get current body
    body = ui.el.closest('.ticketZoom').find('.article-add [data-name="body"]').html() || ''

    # check if quote needs to be added via user selection of content
    signaturePosition = 'bottom'

    if !@hasUserSelectedContent(ui)
      selected = ''
    else
      selected = @getSelectedContent(ui)
      selected = @cleanUpHtmlSelection(selected)

    # full quote, if needed
    if !selected && article && App.Config.get('ui_ticket_zoom_article_email_full_quote')
      signaturePosition = 'top'
      if article.content_type.match('html')
        selected = App.Utils.textCleanup(article.body)
      if article.content_type.match('plain')
        selected = App.Utils.textCleanup(article.body)
        selected = App.Utils.text2html(selected)

    if selected
      quote_header = @replyQuoteHeader(article)

      selected = "<div><br><br/></div><div><blockquote type=\'cite\'>#{quote_header}#{selected}<br></blockquote></div><div><br></div>"

      # add selected text to body
      body = selected + body

    articleNew.body = body

    type = App.TicketArticleType.findByAttribute(name:'email')

    articleNew.subtype = 'reply'

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
      signaturePosition: signaturePosition
    })

    true

  @cleanUpHtmlSelection: (selected) ->
    if selected
      cleaned_up = App.Utils.htmlCleanup(selected).html()

      return cleaned_up if cleaned_up

    text = App.ClipBoard.getSelected('text')
    return App.Utils.text2html(text) if text

    false

  # Fixes Issue #3539 - When replying quote article content only
  @getSelectedContent: (ui) ->
    range          = window.getSelection().getRangeAt(0)
    parentSelector = ui.el.closest('.ticket-article-item').attr('id')

    return if !parentSelector

    lastSelElem = $('#' + parentSelector + ' .richtext-content')[0]

    startInsideArticle = @isInsideSelectionBoundary(range.startContainer, parentSelector)
    endInsideArticle   = @isInsideSelectionBoundary(range.endContainer, parentSelector)

    if !startInsideArticle && endInsideArticle
      range.setStart(lastSelElem, 0)
    else if startInsideArticle && !endInsideArticle
      range.setEnd(lastSelElem, lastSelElem.childNodes.length)
    else if @containsNode(lastSelElem)
      range.setStart(lastSelElem, 0)
      range.setEnd(lastSelElem, lastSelElem.childNodes.length)

    App.ClipBoard.manuallyUpdateSelection()
    App.ClipBoard.getSelected('html')

  # checks if user has made any text selection
  # checks if that text selection is inside article-content only
  @hasUserSelectedContent: (ui) ->
    selObject = App.ClipBoard.getSelectedObject()

    if selObject.rangeCount > 0
      # item on which reply is clicked
      parentTicketArticleContainer = ui.el.closest('.ticket-article-item')
      if parentTicketArticleContainer
        parentSelector = parentTicketArticleContainer.attr('id')
        range = selObject.getRangeAt(0)
        return @isInsideSelectionBoundary(range.startContainer, parentSelector) || @isInsideSelectionBoundary(range.endContainer, parentSelector) || @containsNode($('#' + parentSelector + ' .richtext-content')[0])
    else
      return false

  @isInsideSelectionBoundary: (node, parentSelectorId) ->
    hasParent = $(node).closest('#' + parentSelectorId + ' .richtext-content')
    return hasParent && hasParent.attr('class') is 'richtext-content'

  # Selection.containsNode is not supported in IE, hence check
  @containsNode: (node) ->
    selected = App.ClipBoard.getSelectedObject()
    if typeof selected.containsNode == 'function'
      return selected.containsNode(node, false)
    else
      return false

  @date_format: (date_string) ->
    options = {
      weekday: 'long'
      month: 'long'
      day: 'numeric'
      year: 'numeric'
    }
    locale = App.i18n.get(true)
    try
      new Date(date_string).toLocaleTimeString(locale, options)
    catch e
      new Date(date_string).toLocaleTimeString('en-US', options)

  @emailForward: (ticket, article, ui) ->

    ui.scrollToCompose()

    signaturePosition = 'top'
    body = ''
    if article.content_type.match('html')
      body = App.Utils.textCleanup(article.body)

    if article.content_type.match('plain')
      body = App.Utils.textCleanup(article.body)
      body = App.Utils.text2html(body)

    quote_header = App.FullQuoteHeader.fullQuoteHeaderForward(article)

    body = "<br/><div>---#{App.i18n.translateInline('Begin forwarded message')}:---<br/><br/></div><div><blockquote type=\"cite\">#{quote_header}#{body}</blockquote></div><div><br></div>"

    articleNew = {}
    articleNew.body = body

    if ui.Config.get('ui_ticket_zoom_article_email_subject')
      if _.isEmpty(article.subject)
        articleNew.subject = ticket.title
      else
        articleNew.subject = article.subject

    type = App.TicketArticleType.findByAttribute(name:'email')

    articleNew.subtype = 'forward'

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
      signaturePosition: signaturePosition
      focus: 'to'
    })

    # add attachments to form
    App.Ajax.request(
      id:    "ticket_attachment_clone#{ui.form_id}"
      type:  'POST'
      url:   "#{App.Config.get('api_path')}/ticket_attachment_upload_clone_by_article/#{article.id}"
      data: JSON.stringify(form_id: ui.form_id)
      processData: true
      success: (data, status, xhr) ->
        return if _.isEmpty(data.attachments)
        App.Event.trigger('ui::ticket::addArticleAttachment', {
          ticket: ticket
          article: article
          attachments: data.attachments
          form_id: ui.form_id
        })
    )

    true

  @articleTypes: (articleTypes, ticket, ui) ->
    return articleTypes if ticket.currentView() is 'customer'
    group = ticket.group
    return articleTypes if !group.email_address_id

    attributes = ['to', 'cc', 'subject']
    if !ui.Config.get('ui_ticket_zoom_article_email_subject')
      attributes = ['to', 'cc']
    articleTypes.push {
      name:       'email'
      icon:       'email'
      attributes: attributes
      internal:   false,
      features:   ['attachment', 'security']
    }

    articleTypes

  @setArticleTypePre: (type, ticket, ui, signaturePosition) ->

    # remove old signature
    if type isnt 'email'
      ui.$('[data-name=body] [data-signature=true]').remove()
      return

  @setArticleTypePost: (type, ticket, ui, signaturePosition) ->
    # detect current signature (use current group_id, if not set, use ticket.group_id)
    ticketCurrent = App.Ticket.fullLocal(ticket.id)
    group_id = ticketCurrent.group_id
    task = App.TaskManager.get(ui.taskKey)
    if task && task.state && task.state.ticket && task.state.ticket.group_id
      group_id = task.state.ticket.group_id
    group = App.Group.find(group_id)
    signature = undefined
    if group && group.signature_id
      signature = App.Signature.find(group.signature_id)

    # remove signature if it was added but type is no longer email
    # https://github.com/zammad/zammad/issues/4453
    if type isnt 'email'
      ui.$('[data-name=body] [data-signature="true"]').remove()
      ui.$('[data-name=body]').removeAttr('data-reply-sig-position')
      return

    # Track the intended signature position so updateSignatureByGroup knows where to
    # re-insert a signature when there is a quoted block in the body.  Only update when
    # signaturePosition is explicitly provided (i.e. triggered by an email reply action).
    if signaturePosition?
      if signaturePosition is 'top'
        ui.$('[data-name=body]').attr('data-reply-sig-position', 'top')
      else
        ui.$('[data-name=body]').removeAttr('data-reply-sig-position')

    # add/replace signature
    if signature && signature.active && signature.body

      # If the correct signature is already in the body, preserve it in place to avoid
      # overwriting user-modified signature content (e.g. restoring from autosave).
      # Only apply this shortcut when signaturePosition is not explicitly provided (i.e.
      # the autosave/render path); explicit reply actions must always go through the full
      # removal-and-insertion flow so the position can change (e.g. top → bottom).
      existingTopLevelSignature = ui.$('[data-signature=true]').not('blockquote [data-signature=true]').first()
      if !signaturePosition? && existingTopLevelSignature.length > 0 && existingTopLevelSignature.attr('data-signature-id') is "#{signature.id}"
        # For top-of-body + quoted-block layout, restore the position attribute so a
        # subsequent group change still places the new signature above the quote.
        isAtTop = existingTopLevelSignature.prevAll().filter(-> @nodeName isnt 'BR').length is 0
        hasFollowingQuote = existingTopLevelSignature.nextAll().find('blockquote[type=cite]').length > 0
        if isAtTop && hasFollowingQuote
          ui.$('[data-name=body]').attr('data-reply-sig-position', 'top')
        App.Utils.htmlImage2DataUrlAsyncInline(ui.$('[contenteditable=true]'))
        return

      # remove existing top-level signature (skip signatures in quoted messages)
      # https://github.com/zammad/zammad/issues/5634, https://github.com/zammad/zammad/issues/2319
      ui.$('[data-signature=true]').not('blockquote [data-signature=true]').remove()

      # apply new signature
      signatureFinished = App.Utils.replaceTags(signature.body, { user: App.Session.get(), ticket: ticketCurrent, config: App.Config.all() })

      body = ui.$('[data-name=body]')
      signature = $("<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>")
      App.Utils.htmlStrip(signature)

      placeholder = body.find('[data-signature-placeholder]')
      if placeholder.length > 0
        placeholder[0].replaceWith(signature[0])
      else
        # Detect full-quote layout when signaturePosition is undefined (e.g. autosave restore):
        # orphaned bare BR elements appear at the very start of the body when a full-quote
        # signature (originally prepended with <br><br>) was later removed.
        effectiveSigPosition = signaturePosition
        if not signaturePosition? && body.find('blockquote[type=cite]').length > 0
          firstChild = body.get(0)?.firstChild
          while firstChild?.nodeType is 3   # skip whitespace text nodes
            firstChild = firstChild?.nextSibling
          if firstChild?.nodeName is 'BR'
            effectiveSigPosition = 'top'
            body.attr('data-reply-sig-position', 'top')

        if effectiveSigPosition is 'top'
          body.prepend(signature)
          body.prepend('<br><br>')
        else
          if !App.Utils.htmlLastLineEmpty(body)
            body.append('<br><br>')
          body.append(signature)
      ui.$('[data-name=body]').replaceWith(body)
    else
      body = ui.$('[data-name=body]')

      # When restoring from autosave (signaturePosition not provided), the
      # data-reply-sig-position attribute is lost on reload.  Detect the original
      # full-quote layout: bare BR elements at the very start of the body are the
      # fingerprint left behind when a prepended signature (<br><br> + sig div) was
      # later removed by switching to a no-signature group.  Restoring the attribute
      # now ensures a subsequent group switch to a sig group places the new signature
      # before the quote block rather than after it.
      if not signaturePosition? && body.find('blockquote[type=cite]').length > 0
        firstChild = body.get(0)?.firstChild
        while firstChild?.nodeType is 3   # skip whitespace text nodes
          firstChild = firstChild?.nextSibling
        if firstChild?.nodeName is 'BR'
          ui.$('[data-name=body]').attr('data-reply-sig-position', 'top')

      signatures = body.find('[data-signature-placeholder]')

      if signatures.length > 0
        signatures.each ->
          node = @
          brsToRemove = []
          while(node?.previousSibling?.nodeName == 'BR')
            brsToRemove.push node.previousSibling
            node = node.previousSibling

          brsToRemove.forEach (elem) -> elem.remove()

          @remove()

        ui.$('[data-name=body]').replaceWith(body)

    # convert remote images into data urls
    App.Utils.htmlImage2DataUrlAsyncInline(ui.$('[contenteditable=true]'))

  @updateSignatureByGroup: (type, ticket, ui, newGroupId) ->
    return if type isnt 'email'

    ticketCurrent = App.Ticket.fullLocal(ticket.id)
    group = App.Group.find(newGroupId)
    signature = undefined
    if group && group.signature_id
      signature = App.Signature.find(group.signature_id)

    body = ui.$('[data-name=body]')

    if signature && signature.active && signature.body

      # apply new signature
      signatureFinished = App.Utils.replaceTags(signature.body, { user: App.Session.get(), ticket: ticketCurrent, config: App.Config.all() })

      newSig = $("<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>")
      App.Utils.htmlStrip(newSig)

      existingSignature = body.find('[data-signature=true]').not('blockquote [data-signature=true]').first()
      if existingSignature.length > 0
        # replace in-place to preserve the signature's position in the body
        existingSignature.replaceWith(newSig[0])
      else
        # Check if the signature should go before or after a quoted block.
        # 'top' means full-quote reply (sig belongs above the quote structure);
        # anything else means inline/no-quote reply (sig belongs at the end).
        sigPosition = body.attr('data-reply-sig-position')
        topLevelBlockquote = body.find('blockquote[type=cite]').first()
        if topLevelBlockquote.length > 0 && sigPosition is 'top'
          # if there is a full quote in the body, place the signature before the quote structure
          parents = topLevelBlockquote.parentsUntil(body)
          quoteContainer = if parents.length > 0 then parents.last() else topLevelBlockquote
          prevElement = quoteContainer.prev()
          if prevElement.length > 0
            prevElement.before(newSig)
          else
            quoteContainer.before(newSig)
          # add blank lines before the signature if none are already present, so the
          # user has space to type above it
          unless newSig[0].previousSibling?.nodeName is 'BR'
            newSig.before('<br><br>')
        else
          if !App.Utils.htmlLastLineEmpty(body)
            body.append('<br><br>')
          body.append(newSig)
    else
      # no signature for the new group → remove any existing signature
      body.find('[data-signature=true]').not('blockquote [data-signature=true]').remove()

    ui.$('[data-name=body]').replaceWith(body)

    # convert remote images into data urls
    App.Utils.htmlImage2DataUrlAsyncInline(ui.$('[contenteditable=true]'))

  @validation: (type, params, ui) ->
    return true if type isnt 'email'

    # check if recipient exists
    if _.isEmpty(params.to) && _.isEmpty(params.cc)
      new App.ControllerModal(
        head: __('Text missing')
        buttonCancel: __('Cancel')
        buttonCancelClass: 'btn--danger'
        buttonSubmit: false
        message: __('Please provide a recipient in "TO" or "CC".')
        shown: true
        small: true
        container: ui.el.closest('.content')
      )
      return false

    # check if message exists
    if _.isEmpty(params.body)
      new App.ControllerModal(
        head: __('Text missing')
        buttonCancel: __('Cancel')
        buttonCancelClass: 'btn--danger'
        buttonSubmit: false
        message: __('Text needed')
        shown: true
        small: true
        container: ui.el.closest('.content')
      )
      return false

    true

  @replyQuoteHeader: (article) ->
    if !App.Config.get('ui_ticket_zoom_article_email_full_quote_header')
      return ''

    date = @date_format(article.created_at)
    name = article.recipientName()

    App.i18n.translateInline('On %s, %s wrote:', date, name) + '<br><br>'


App.Config.set('200-EmailReply', EmailReply, 'TicketZoomArticleAction')
