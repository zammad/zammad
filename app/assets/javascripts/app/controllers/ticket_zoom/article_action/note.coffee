class Note
  @action: (actions, ticket, article, ui) ->
    return actions if !ticket.editable()
    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    true

  @articleTypes: (articleTypes, ticket, ui) ->
    articleTypes

App.Config.set('100-Note', Note, 'TicketZoomArticleAction')
