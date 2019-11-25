class App.TicketZoomArticleActions extends App.Controller
  events:
    'click .js-ArticleAction': 'actionPerform'

  constructor: ->
    super
    @render()

  render: =>
    actions = @actionRow(@ticket, @article)

    if actions
      @html App.view('ticket_zoom/article_view_actions')(
        article: @article
        actions: actions
      )
    else
      @html ''

  actionRow: (ticket, article) ->
    actionConfig = App.Config.get('TicketZoomArticleAction')
    keys = _.keys(actionConfig).sort()
    actions = []
    for key in keys
      config = actionConfig[key]
      if config
        actions = config.action(actions, ticket, article, @)
    actions

  actionPerform: (e) =>
    e.preventDefault()

    articleContainer = $(e.target).closest('.ticket-article-item')
    type = $(e.currentTarget).attr('data-type')
    ticket = App.Ticket.fullLocal(@ticket.id)
    article = App.TicketArticle.fullLocal(@article.id)

    actionConfig = App.Config.get('TicketZoomArticleAction')
    keys = _.keys(actionConfig).sort()
    actions = []
    for key in keys
      config = actionConfig[key]
      if config
        return if !config.perform(articleContainer, type, ticket, article, @)

  scrollToCompose: =>
    @el.closest('.content').find('.article-add').ScrollTo()
