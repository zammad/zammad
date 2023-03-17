class PhoneReply
  @action: (actions, ticket, article, ui) ->
    return actions if !ticket.editable()
    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    true

  @articleTypes: (articleTypes, ticket, ui) ->
    return articleTypes if ticket.currentView() is 'customer'
    articleTypes.push {
      name:       __('phone')
      icon:       'phone'
      attributes: []
      internal:   false,
      features:   ['attachment']
    }
    articleTypes

App.Config.set('100-PhoneReply', PhoneReply, 'TicketZoomArticleAction')
