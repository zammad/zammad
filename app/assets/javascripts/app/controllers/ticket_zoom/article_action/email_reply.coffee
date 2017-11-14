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
    if article.sender.name is 'Customer' && article.type.name is 'phone'
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
    if article.sender.name is 'Agent' && article.type.name is 'phone'
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'emailReply' && type isnt 'emailReplyAll'

    if type isnt 'emailReply'
      @emailReply(true, ticket, article, ui)

    else if type isnt 'emailReplyAll'
      @emailReply(false, ticket, article, ui)

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

App.Config.set('200-EmailReply', EmailReply, 'TicketZoomArticleAction')
