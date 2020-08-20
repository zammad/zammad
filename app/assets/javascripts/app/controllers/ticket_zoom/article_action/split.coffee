class Split
  @action: (actions, ticket, article, ui) ->
    return actions if ticket.currentView() is 'customer'

    actions.push {
      name: 'split'
      type: 'split'
      icon: 'split'
      href: "#ticket/create/#{article.ticket_id}/#{article.id}"
    }
    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'split'
    ui.navigate "#ticket/create/#{article.ticket_id}/#{article.id}"
    true

App.Config.set('700-Split', Split, 'TicketZoomArticleAction')
