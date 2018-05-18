class EmailReply extends App.Controller
  @action: (actions, ticket, article, ui) ->
    return actions if !ui.permissionCheck('ticket.agent')
    group = ticket.group
    return actions if !group.email_address_id

    if article.type.name is 'email' || article.type.name is 'web'
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }

      # check if reply all need to be shown
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
      forgeinRecipients = []
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
              forgeinRecipients.push recipient

      # check if reply all is neede
      if forgeinRecipients.length > 1
        actions.push {
          name: 'reply all'
          type: 'emailReplyAll'
          icon: 'reply-all'
          href: '#'
        }

      # always show forward
      actions.push {
        name: 'forward'
        type: 'emailForward'
        icon: 'forward'
        href: '#'
      }

    if article.sender.name is 'Customer' && article.type.name is 'phone'
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
      actions.push {
        name: 'forward'
        type: 'emailForward'
        icon: 'forward'
        href: '#'
      }
    if article.sender.name is 'Agent' && article.type.name is 'phone'
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
      actions.push {
        name: 'forward'
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

    # check if quote need to be added
    signaturePosition = 'bottom'
    selected = App.ClipBoard.getSelected('html')
    if selected
      selected = App.Utils.htmlCleanup(selected).html()
      selected = App.Utils.htmlImage2DataUrl(selected)
    if !selected
      selected = App.ClipBoard.getSelected('text')
      if selected
        selected = App.Utils.textCleanup(selected)
        selected = App.Utils.text2html(selected)

    # full quote, if needed
    if !selected && article && App.Config.get('ui_ticket_zoom_article_email_full_quote')
      signaturePosition = 'top'
      if article.content_type.match('html')
        selected = App.Utils.textCleanup(article.body)
      if article.content_type.match('plain')
        selected = App.Utils.textCleanup(article.body)
        selected = App.Utils.text2html(selected)

    if selected
      selected = "<div><br><br/></div><div><blockquote type=\"cite\">#{selected}</blockquote></div><div><br></div>"

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

  @emailForward: (ticket, article, ui) ->

    ui.scrollToCompose()

    signaturePosition = 'top'
    body = ''
    if article.content_type.match('html')
      body = App.Utils.textCleanup(article.body)
      body = App.Utils.htmlImage2DataUrl(article.body)

    if article.content_type.match('plain')
      body = App.Utils.textCleanup(article.body)
      body = App.Utils.text2html(body)

    body = "<br/><div>---Begin forwarded message:---<br/><br/></div><div><blockquote type=\"cite\">#{body}</blockquote></div><div><br></div>"

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
        App.Event.trigger('ui::ticket::addArticleAttachent', {
          ticket: ticket
          article: article
          attachments: data.attachments
          form_id: ui.form_id
        })
    )

    true

  @articleTypes: (articleTypes, ticket, ui) ->
    return articleTypes if !ui.permissionCheck('ticket.agent')
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
      features:   ['attachment']
    }

    articleTypes

  @setArticleTypePre: (type, ticket, ui, signaturePosition) ->

    # remove old signature
    if type isnt 'email'
      ui.$('[data-name=body] [data-signature=true]').remove()
      return

  @setArticleTypePost: (type, ticket, ui, signaturePosition) ->
    return if type isnt 'email'

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

    # add/replace signature
    if signature && signature.body

      # if signature has changed, remove it
      signature_id = ui.$('[data-signature=true]').data('signature-id')
      if signature_id && signature_id.toString() isnt signature.id.toString()
        ui.$('[data-name=body] [data-signature="true"]').remove()

      # apply new signature
      signatureFinished = App.Utils.replaceTags(signature.body, { user: App.Session.get(), ticket: ticketCurrent, config: App.Config.all() })

      body = ui.$('[data-name=body]')
      if App.Utils.signatureCheck(body.html() || '', signatureFinished)
        if !App.Utils.htmlLastLineEmpty(body)
          body.append('<br><br>')
        signature = $("<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>")
        App.Utils.htmlStrip(signature)
        if signaturePosition is 'top'
          body.prepend(signature)
        else
          body.append(signature)
        ui.$('[data-name=body]').replaceWith(body)

  @validation: (type, params, ui) ->
    return true if type isnt 'email'

    # check if recipient exists
    if _.isEmpty(params.to) && _.isEmpty(params.cc)
      new App.ControllerModal(
        head: 'Text missing'
        buttonCancel: 'Cancel'
        buttonCancelClass: 'btn--danger'
        buttonSubmit: false
        message: 'Need recipient in "To" or "Cc".'
        shown: true
        small: true
        container: ui.el.closest('.content')
      )
      return false

    # check if message exists
    if _.isEmpty(params.body)
      new App.ControllerModal(
        head: 'Text missing'
        buttonCancel: 'Cancel'
        buttonCancelClass: 'btn--danger'
        buttonSubmit: false
        message: 'Text needed'
        shown: true
        small: true
        container: ui.el.closest('.content')
      )
      return false

    true

App.Config.set('200-EmailReply', EmailReply, 'TicketZoomArticleAction')
