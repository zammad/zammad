class App.TicketZoomEmailUnprocessable extends App.Controller
  constructor: ->
    super
    @render()

  execute: (params) =>
    @ticket_article_ids = params.ticket_article_ids
    @render()

  render: =>
    articles = @flaggedArticles()

    if _.isEmpty(articles)
      @html ''
      @el.addClass('hide')
      return

    @html App.view('ticket_zoom/email_unprocessable')(
      warnings: _.map(articles, (article) =>
        articleId:        article.id
        rawEmailUrl:      @attachmentUrl(article, 'raw')
        processingLogUrl: @attachmentUrl(article, 'log')
      )
    )
    @el.removeClass('hide')

  # Every flagged article is rendered as a warning only, not as an article, as in the desktop and mobile views.
  @flaggedArticleIds: (ticket_article_ids) ->
    _.filter(ticket_article_ids, (articleId) ->
      App.TicketArticle.exists(articleId) and App.TicketArticle.find(articleId).preferences?.email_unprocessable is true
    )

  flaggedArticles: =>
    _.map(@constructor.flaggedArticleIds(@ticket_article_ids), (articleId) -> App.TicketArticle.find(articleId))

  attachmentUrl: (article, marker) =>
    attachment = _.find(article.attachments, (attachment) -> attachment.preferences?.email_unprocessable is marker)
    return if !attachment

    "#{@Config.get('api_path')}/ticket_attachment/#{article.ticket_id}/#{article.id}/#{attachment.id}?disposition=attachment"
