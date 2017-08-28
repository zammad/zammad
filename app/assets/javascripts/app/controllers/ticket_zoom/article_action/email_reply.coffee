class EmailReply extends App.Controller
  @action: (actions, ticket, article, ui) ->
    return actions if ui.permissionCheck('ticket.customer')

    group = ticket.group
    if group.email_address_id && (article.type.name is 'email' || article.type.name is 'web')
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
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

      actions.push {
        name: 'forward'
        type: 'emailForward'
        #icon: 'forward'
        icon: 'line-right-arrow'
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
        #icon: 'forward'
        icon: 'line-right-arrow'
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
        #icon: 'forward'
        icon: 'line-right-arrow'
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

    # get current body
    body = ui.el.closest('.ticketZoom').find('.article-add [data-name="body"]').html() || ''

    # check if quote need to be added
    signaturePosition = 'bottom'
    selected = App.ClipBoard.getSelected('html')
    if selected
      selected = App.Utils.htmlCleanup(selected).html()
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
    if article.content_type.match('plain')
      body = App.Utils.textCleanup(article.body)
      body = App.Utils.text2html(body)

    body = "<br/><div>---Begin forwarded message:---<br/><br/></div><div><blockquote type=\"cite\">#{body}</blockquote></div><div><br></div>"

    articleNew = {}
    articleNew.body = body

    type = App.TicketArticleType.findByAttribute(name:'email')

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
      signaturePosition: signaturePosition
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

App.Config.set('200-EmailReply', EmailReply, 'TicketZoomArticleAction')
