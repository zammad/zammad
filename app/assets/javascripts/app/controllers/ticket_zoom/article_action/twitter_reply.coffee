class TwitterReply
  @action: (actions, ticket, article, ui) ->
    return actions if ticket.currentView() is 'customer'

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

    if !articleNew.to && customer && customer.accounts
      articleNew.to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
    })

  @articleTypes: (articleTypes, ticket, ui) ->
    return articleTypes if ticket.currentView() is 'customer'

    return articleTypes if !ticket || !ticket.create_article_type_id

    articleTypeCreate = App.TicketArticleType.find(ticket.create_article_type_id).name
    if articleTypeCreate is 'twitter status'
      attributes = ['body:limit', 'body:initials']
      if !ui.Config.get('ui_ticket_zoom_article_twitter_initials')
        attributes = ['body:limit']
      articleTypes.push {
        name:              'twitter status'
        icon:              'twitter'
        attributes:        []
        internal:          false,
        features:          attributes
        maxTextLength:     280
        warningTextLength: 30
      }
    else if articleTypeCreate is 'twitter direct-message'
      attributes = ['body:limit', 'body:initials']
      if !ui.Config.get('ui_ticket_zoom_article_twitter_initials')
        attributes = ['body:limit']
      articleTypes.push {
        name:              'twitter direct-message'
        icon:              'twitter'
        attributes:        ['to']
        internal:          false,
        features:          attributes
        maxTextLength:     10000
        warningTextLength: 500
      }

    articleTypes

  @validation: (type, params, ui) ->
    if type is 'twitter status'
      textLength = ui.maxTextLength - App.Utils.textLengthWithUrl(params.body)
      return false if textLength < 0

    if params.type is 'twitter direct-message'
      textLength = ui.maxTextLength - App.Utils.textLengthWithUrl(params.body)
      return false if textLength < 0

      # check if recipient exists
      if _.isEmpty(params.to)
        new App.ControllerModal(
          head: 'Text missing'
          buttonCancel: 'Cancel'
          buttonCancelClass: 'btn--danger'
          buttonSubmit: false
          message: 'Need recipient in "To".'
          shown: true
          small: true
          container: ui.el.closest('.content')
        )
        return false

    true

  @setArticleTypePost: (type, ticket, ui) ->
    return if type isnt 'twitter status' && type isnt 'twitter direct-message'
    rawHTML = ui.$('[data-name=body]').html()
    cleanHTML = App.Utils.htmlRemoveRichtext(rawHTML)
    if cleanHTML && cleanHTML.html() != rawHTML
      ui.$('[data-name=body]').html(cleanHTML)

  @params: (type, params, ui) ->
    if type is 'twitter status'
      App.Utils.htmlRemoveRichtext(ui.$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    if type is 'twitter direct-message'
      App.Utils.htmlRemoveRichtext(ui.$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    params

App.Config.set('300-TwitterReply', TwitterReply, 'TicketZoomArticleAction')
