class TelegramReply
  @action: (actions, ticket, article, ui) ->
    return actions if ui.permissionCheck('ticket.customer')

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

App.Config.set('300-TelegramReply', TelegramReply, 'TicketZoomArticleAction')
