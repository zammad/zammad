class WhatsappReply
  @action: (actions, ticket, article, ui) ->
    return actions if !ticket.editable()
    return actions if ticket.currentView() is 'customer'
    return actions if article.type.name isnt 'whatsapp message'
    return actions if !@canUseWhatsapp(ticket)

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

    return articleTypes if !@canUseWhatsapp(ticket)

    articleTypeCreate = App.TicketArticleType.find(ticket.create_article_type_id).name

    return articleTypes if articleTypeCreate isnt 'whatsapp message'

    articleTypes.push {
      name:              'whatsapp message'
      icon:              'whatsapp'
      attributes:        []
      internal:          false,
      features:          ['body:limit', 'attachment', 'attachments:limit', 'attachments:size', 'body:ensureNoCaption', 'body:allowNoCaption']
      maxTextLength:     4096
      warningTextLength: -1
      attachmentsLimit:  1
      attachmentsSize:   [
        { size: 16 * 1024 * 1024,  label: __('Audio file'),    content_types: ['audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/amr', 'audio/ogg'] },
        { size: 5 * 1024 * 1024,   label: __('Image file'),    content_types: ['image/jpeg', 'image/png'] },
        { size: 16 * 1024 * 1024,  label: __('Video file'),    content_types: ['video/mp4', 'video/3gp'] },
        { size: 500 * 1024,        label: __('Sticker file'),  content_types: ['image/webp'] },
        { size: 100 * 1024 * 1024, label: __('Document file'), content_types: ['text/plain', 'application/pdf', 'application/vnd.ms-powerpoint', 'application/msword', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'] },
      ],
      bodyEnsureNoCaption: (attachmentsTypes) ->
        base = __('%s is sent without text caption')

        if _.intersection(attachmentsTypes, ['audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/amr', 'audio/ogg']).length
          App.i18n.translateContent base, App.i18n.translateContent(__('Audio file'))
        else if _.intersection(attachmentsTypes, ['image/webp']).length
          App.i18n.translateContent base, App.i18n.translateContent(__('Sticker file'))
        else
          false
      bodyAllowNoCaption: (attachments) ->
        attachments.length > 0
    }

    articleTypes

  @params: (type, params, ui) ->
    if type is 'whatsapp message'
      App.Utils.htmlRemoveRichtext(ui.$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    params

  @canUseWhatsapp: (ticket) ->
    alert = new App.TicketZoomChannel(ticket).channelAlert()

    alert?.type and alert.type != 'danger'

App.Config.set('300-WhatsappReply', WhatsappReply, 'TicketZoomArticleAction')
