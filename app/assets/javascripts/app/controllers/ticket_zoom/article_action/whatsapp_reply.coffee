class WhatsappReply
  @action: (actions, ticket, article, ui) ->
    return actions if !ticket.editable()
    return actions if ticket.currentView() is 'customer'
    return actions if article.type.name isnt 'whatsapp message'

    actions.push {
      name: __('reply')
      type: 'whatsappReply'
      icon: 'reply'
      href: '#'
    }

    actions

  @perform: (articleContainer, type, ticket, article, ui) ->
    return true if type isnt 'whatsappReply'

    ui.scrollToCompose()

    type = App.TicketArticleType.findByAttribute('name', 'whatsapp message')

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

    return articleTypes if articleTypeCreate isnt 'whatsapp message'

    articleTypes.push {
      name:              'whatsapp message'
      icon:              'whatsapp'
      attributes:        []
      internal:          false,
      features:          ['body:limit', 'attachment']
      maxTextLength:     4096
      warningTextLength: -1
    }

    articleTypes

  @params: (type, params, ui) ->
    if type is 'whatsapp message'
      App.Utils.htmlRemoveRichtext(ui.$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    params

App.Config.set('300-WhatsappReply', WhatsappReply, 'TicketZoomArticleAction')
