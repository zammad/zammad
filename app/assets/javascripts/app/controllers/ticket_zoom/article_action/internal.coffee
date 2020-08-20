class Internal
  @action: (actions, ticket, article, ui) ->
    return actions if ticket.currentView() is 'customer'

    if article.internal is true
      actions.push {
        name: 'set to public'
        type: 'public'
        icon: 'lock-open'
      }
    else
      actions.push {
        name: 'set to internal'
        type: 'internal'
        icon: 'lock'
      }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'internal' && type isnt 'public'

    # storage update
    internal = true
    if article.internal == true
      internal = false
    ui.lastAttributres.internal = internal
    article.updateAttributes(internal: internal)

    # runtime update
    if internal
      articleContainer.addClass('is-internal')
    else
      articleContainer.removeClass('is-internal')

    ui.render()

    true

App.Config.set('100-Internal', Internal, 'TicketZoomArticleAction')
