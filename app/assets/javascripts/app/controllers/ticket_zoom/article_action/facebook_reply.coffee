class FacebookReply
  @action: (actions, ticket, article, ui) ->
    return actions if ticket.currentView() is 'customer'

    if article.type.name is 'facebook feed post' || article.type.name is 'facebook feed comment'
      actions.push {
        name: 'reply'
        type: 'facebookFeedReply'
        icon: 'reply'
        href: '#'
      }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'facebookFeedReply'

    ui.scrollToCompose()

    type = App.TicketArticleType.findByAttribute('name', 'facebook feed comment')

    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    App.Event.trigger('ui::ticket::setArticleType', {
      ticket: ticket
      type: type
      article: articleNew
    })

    true

  @articleTypes: (articleTypes, ticket, ui) ->
    return articleTypes if ticket.currentView() is 'customer'

    return articleTypes if !ticket || !ticket.create_article_type_id

    articleTypeCreate = App.TicketArticleType.find(ticket.create_article_type_id).name
    if articleTypeCreate is 'facebook feed post'
      articleTypes.push {
        name:       'facebook feed comment'
        icon:       'facebook'
        attributes: []
        internal:   false,
        features:   []
      }
    articleTypes

  @params: (type, params, ui) ->
    if type is 'facebook feed comment'
      App.Utils.htmlRemoveRichtext(ui.$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    params

App.Config.set('300-FacebookReply', FacebookReply, 'TicketZoomArticleAction')
