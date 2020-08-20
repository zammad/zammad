class PhoneReply
  @action: (actions, ticket, article, ui) ->
    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    true

  @articleTypes: (articleTypes, ticket, ui) ->
    return articleTypes if ticket.currentView() is 'customer'
    articleTypes.push {
      name:       'phone'
      icon:       'phone'
      attributes: []
      internal:   false,
      features:   ['attachment']
    }
    articleTypes

App.Config.set('100-PhoneReply', PhoneReply, 'TicketZoomArticleAction')
