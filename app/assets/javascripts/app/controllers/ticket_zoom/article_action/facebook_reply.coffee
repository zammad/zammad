class FacebookReply
  @action: (actions, ticket, article, ui) ->
    return actions if ui.permissionCheck('ticket.customer')

    if article.type.name is 'facebook feed post' || article.type.name is 'facebook feed comment'
      actions.push {
        name: 'reply'
        type: 'facebookFeedReply'
        icon: 'reply'
        href: '#'
      }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'facebookFeedReply'

    ui.scrollToCompose()

    type = App.TicketArticleType.findByAttribute('name', 'facebook feed comment')

    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
    })

    true

App.Config.set('300-FacebookReply', FacebookReply, 'TicketZoomArticleAction')
