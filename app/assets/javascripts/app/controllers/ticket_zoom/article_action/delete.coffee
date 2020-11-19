class Delete
  @action: (actions, ticket, article, ui) ->
    status = @isDeletable(actions, ticket, article, ui)

    return actions if !status.isDeletable

    actions.push {
      name: 'delete'
      type: 'delete'
      icon: 'trash'
      href: '#'
    }

    # rerender actions if ability to delete expires
    if status.timeout
      ui.delay(ui.render, status.timeout, 'actions-rerender')

    actions

  @isDeletable: (actions, ticket, article, ui) ->
    return { isDeletable: false } if !@deletableForAgent(actions, ticket, article, ui)
    return { isDeletable: true }  if !@hasDeletableTimeframe()

    timeout = @deletableTimeout(actions, ticket, article, ui)

    return { isDeletable: false } if timeout <= 0

    { isDeletable: true, timeout: timeout }

  @deletableTimeframeSetting: ->
    App.Config.get('ui_ticket_zoom_article_delete_timeframe')

  @hasDeletableTimeframe: ->
    @deletableTimeframeSetting() && @deletableTimeframeSetting() > 0

  @deletableTimeout: (actions, ticket, article, ui) ->
    timeframe_miliseconds = @deletableTimeframeSetting() * 1000
    now                   = Date.parse(new Date())
    created_at            = Date.parse(article.created_at)

    timeframe_miliseconds - (now - created_at)

  @deletableForAgent: (actions, ticket, article, ui) ->
    return false if ticket.currentView() is 'customer'
    return false if article.created_by_id != App.User.current()?.id
    return false if article.type.communication && !article.internal

    true

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
