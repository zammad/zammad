class Delete
  @action: (actions, ticket, article, ui) ->
    return actions if ui.permissionCheck('ticket.customer')

    return actions if article.type.name isnt 'note'

    return actions if App.User.current()?.id != article.created_by_id

    return actions if !ui.permissionCheck('ticket.agent')

    # return if article is older then 10 minutes
    created_at = Date.parse(article.created_at)
    time_to_show = 600000 - (Date.parse(new Date()) - created_at)

    return actions if time_to_show <= 0

    actions.push {
      name: 'delete'
      type: 'delete'
      icon: 'trash'
      href: '#'
    }

    # rerender ations in 10 minutes again to hide delete action of article
    ui.delay(ui.render, time_to_show, 'actions-rerender')

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
