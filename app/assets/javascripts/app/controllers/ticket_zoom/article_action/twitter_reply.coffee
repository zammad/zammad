class TwitterReply
  @action: (actions, ticket, article, ui) ->
    return actions if ui.permissionCheck('ticket.customer')

    if article.type.name is 'twitter status'
      actions.push {
        name: 'reply'
        type: 'twitterStatusReply'
        icon: 'reply'
        href: '#'
      }
    if article.type.name is 'twitter direct-message'
      actions.push {
        name: 'reply'
        type: 'twitterDirectMessageReply'
        icon: 'reply'
        href: '#'
      }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'twitterStatusReply' && type isnt 'twitterDirectMessageReply'

    if type is 'twitterStatusReply'
      @twitterStatusReply(ticket, article, ui)

    else if type is 'twitterDirectMessageReply'
      @twitterDirectMessageReply(ticket, article, ui)

    true

  @twitterStatusReply: (ticket, article, ui) ->

    ui.scrollToCompose()

    # get reference article
    type = App.TicketArticleType.find(article.type_id)

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    if article.message_id
      articleNew.in_reply_to = article.message_id

    # get current body
    body = ui.el.closest('.ticketZoom').find('.article-add [data-name="body"]').html().trim() || ''
    articleNew.body = body

    recipients = article.from
    if article.to
      if recipients
        recipients += ', '
      recipients += article.to

    if recipients
      recipientString = ''
      recipientScreenNames = recipients.split(',')
      for recipientScreenName in recipientScreenNames
        if recipientScreenName
          recipientScreenName = recipientScreenName.trim().toLowerCase()

          # exclude already listed screen name
          exclude = false
          if body && body.toLowerCase().match(recipientScreenName)
            exclude = true

          # exclude own screen_name
          if recipientScreenName is "@#{ticket.preferences.channel_screen_name}".toLowerCase()
            exclude = true

          if exclude is false
            if recipientString isnt ''
              recipientString += ' '
            recipientString += recipientScreenName

    if body
      articleNew.body = "#{recipientString} #{body}&nbsp;"
    else
      articleNew.body = "#{recipientString}&nbsp;"

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
      position: 'end'
    })

  @twitterDirectMessageReply: (ticket, article, ui) ->

    # get reference article
    type       = App.TicketArticleType.find(article.type_id)
    sender     = App.TicketArticleSender.find(article.sender_id)
    customer   = App.User.find(article.created_by_id)

    ui.scrollToCompose()

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    if article.message_id
      articleNew.in_reply_to = article.message_id

    if sender.name is 'Agent'
      articleNew.to = article.to
    else
      articleNew.to = article.from

    if !articleNew.to
      articleNew.to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
    })

App.Config.set('300-TwitterReply', TwitterReply, 'TicketZoomArticleAction')
