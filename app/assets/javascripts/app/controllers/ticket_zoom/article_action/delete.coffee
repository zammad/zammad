class Delete
  @action: (actions, ticket, article, ui) ->
    return actions if ui.permissionCheck('ticket.customer')

    if article.type.name is 'note'
      if App.User.current()?.id == article.created_by_id && ui.permissionCheck('ticket.agent')
        actions.push {
          name: 'delete'
          type: 'delete'
          icon: 'trash'
          href: '#'
        }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'delete'

    callback = ->
      article = App.TicketArticle.find(article.id)
      article.destroy()

    new App.ControllerConfirm(
      message: 'Sure?'
      callback: callback
      container: ui.el.closest('.content')
    )

    true

App.Config.set('900-Delete', Delete, 'TicketZoomArticleAction')
