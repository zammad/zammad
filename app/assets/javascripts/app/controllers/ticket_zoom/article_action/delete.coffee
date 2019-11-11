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
      article.destroy(
        fail: (article, details) ->
          ui.log 'errors', details
          ui.notify(
            type:    'error'
            msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to delete article!')
            timeout: 6000
        )
      )

    new App.ControllerConfirm(
      message: 'Sure?'
      callback: callback
      container: ui.el.closest('.content')
    )

    true

App.Config.set('900-Delete', Delete, 'TicketZoomArticleAction')
