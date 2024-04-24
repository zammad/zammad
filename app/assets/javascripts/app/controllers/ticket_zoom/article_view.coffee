class App.TicketZoomArticleView extends App.Controller
  constructor: ->
    super
    @articleController = {}
    @run()

  execute: (params) =>
    @ticket_article_ids = params.ticket_article_ids
    @run()

  run: =>
    all = []
    for ticket_article_id, index in @ticket_article_ids
      controllerKey = ticket_article_id.toString()
      if !@articleController[controllerKey]
        el = $('<div></div>')
        @articleController[controllerKey] = new App.ArticleViewItem(
          ticket:     @ticket
          object_id:  ticket_article_id
          el:         el
          ui:         @ui
          highlighter: @highlighter
          form_id:    @form_id
        )
        if !@ticketArticleInsertByIndex(index, el)
          all.push el
    @el.append(all)

    # check elements to remove
    for article_id, controller of @articleController
      exists = false
      for localArticleId in @ticket_article_ids
        if localArticleId.toString() is article_id.toString()
          exists = true
      if !exists
        controller.remove()
        delete @articleController[article_id.toString()]

  ticketArticleInsertByIndex: (elIndex, el) =>
    return false if !@$('.ticket-article-item').length

    # in case of a merge it can happen that there are already
    # articles rendered in the ticket, but the new article need
    # to be inserted at the correct position in the the ticket
    for index in [elIndex .. 0]
      article_id = @ticket_article_ids[index]
      continue if !article_id
      article = @$(".ticket-article-item[data-id=#{article_id}]")
      continue if !article.length
      article.after(el)
      return true

    for index in [elIndex .. @ticket_article_ids.length - 1]
      article_id = @ticket_article_ids[index]
      continue if !article_id
      article = @$(".ticket-article-item[data-id=#{article_id}]")
      continue if !article.length
      article.before(el)
      return true

    false

  updateFormId: (newFormId) ->
    @form_id = newFormId

    for id, viewItem of @articleController
      viewItem.updateFormId(newFormId)

