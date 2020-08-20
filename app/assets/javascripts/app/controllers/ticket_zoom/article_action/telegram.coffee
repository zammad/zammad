class TelegramReply
  @action: (actions, ticket, article, ui) ->
    return actions if ticket.currentView() is 'customer'

    if article.sender.name is 'Customer' && article.type.name is 'telegram personal-message'
      actions.push {
        name: 'reply'
        type: 'telegramPersonalMessageReply'
        icon: 'reply'
        href: '#'
      }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'telegramPersonalMessageReply'

    ui.scrollToCompose()

    # get reference article
    type = App.TicketArticleType.find(article.type_id)

    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    if article.message_id
      articleNew.in_reply_to = article.message_id

    # get current body
    articleNew.body = ui.el.closest('.ticketZoom').find('.article-add [data-name="body"]').html().trim() || ''

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
      position: 'end'
    })

    true

  @articleTypes: (articleTypes, ticket, ui) ->
    return articleTypes if ticket.currentView() is 'customer'

    return articleTypes if !ticket || !ticket.create_article_type_id

    articleTypeCreate = App.TicketArticleType.find(ticket.create_article_type_id).name

    return articleTypes if articleTypeCreate isnt 'telegram personal-message'
    articleTypes.push {
      name:              'telegram personal-message'
      icon:              'telegram'
      attributes:        []
      internal:          false,
      features:          ['attachment']
      maxTextLength:     10000
      warningTextLength: 5000
    }
    articleTypes

  @setArticleTypePost: (type, ticket, ui) ->
    return if type isnt 'telegram personal-message'
    rawHTML = ui.$('[data-name=body]').html()
    cleanHTML = App.Utils.htmlRemoveRichtext(rawHTML)
    if cleanHTML && cleanHTML.html() != rawHTML
      ui.$('[data-name=body]').html(cleanHTML)

  @params: (type, params, ui) ->
    if type is 'telegram personal-message'
      App.Utils.htmlRemoveRichtext(ui.$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    params

App.Config.set('300-TelegramReply', TelegramReply, 'TicketZoomArticleAction')
