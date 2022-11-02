class SidebarArticleAttachments extends App.Controller
  constructor: ->
    super
    @controllerBind('ui::ticket::load', (data) =>
      return if data.ticket_id.toString() isnt @ticket.id.toString()
      return if !@el
      @showObjects(@el)
    )

  sidebarItem: =>
    return if !@Config.get('ui_ticket_zoom_sidebar_article_attachments')
    @item = {
      name: 'attachment'
      badgeIcon: 'paperclip'
      sidebarHead: __('Attachments')
      sidebarCallback: @showObjects
      sidebarActions: []
    }
    @item

  showObjects: (el) =>
    @el = el

    if _.isEmpty(@ticket) || _.isEmpty(@ticket.article_ids)
      @el.html("<div>#{App.i18n.translateInline('none')}</div>")
      return

    articleIDs = _.clone(@ticket.article_ids)
    articleIDs.sort((a, b) -> a - b)

    uniqueAttachments = {}
    ticketAttachments = []
    for articleID in articleIDs
      continue if !App.TicketArticle.exists(articleID)

      article = App.TicketArticle.find(articleID)
      attachments = App.TicketArticle.contentAttachments(article)
      for attachment in attachments
        continue if uniqueAttachments[attachment.store_file_id]
        uniqueAttachments[attachment.store_file_id] = true

        ticketAttachments.push({ attachment: attachment, article: article })

    ticketAttachments = ticketAttachments.reverse()

    html = App.view('ticket_zoom/sidebar_article_attachment')(
      ticketAttachments: ticketAttachments,
    )

    @el.html(html)
    @el.find('.js-attachments img').click(@imageView)
    @el.find('.file-calendar .js-preview').click(@calendarView)

  imageView: (e) ->
    e.preventDefault()
    e.stopPropagation()
    new App.TicketZoomArticleImageView(image: $(e.target).get(0).outerHTML)

  calendarView: (e) ->
    e.preventDefault()
    e.stopPropagation()
    parentElement = $(e.target).closest('.attachment.file-calendar')
    new App.TicketZoomArticleCalendarView(calendar: parentElement.get(0).outerHTML)

App.Config.set('900-ArticleAttachments', SidebarArticleAttachments, 'TicketZoomSidebar')
