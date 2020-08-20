class Note
  @action: (actions, ticket, article, ui) ->
    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    true

  @articleTypes: (articleTypes, ticket, ui) ->
    internal = false
    if ticket.currentView() is 'agent'
      internal = ui.Config.get('ui_ticket_zoom_article_note_new_internal')

    articleTypes.push {
      name:       'note'
      icon:       'note'
      attributes: []
      internal:   internal,
      features:   ['attachment']
    }

    articleTypes

App.Config.set('100-Note', Note, 'TicketZoomArticleAction')
