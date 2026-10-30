class TicketOverview extends App.PopoverProviderAjax
  @selectorCssClassPrefix = 'ticket-overview'
  @templateName           = 'ticket_overview'
  @titleTemplateName      = 'ticket_overview_title'
  @dataCacheTTL           = 30000

  constructor: ->
    super

    # The overview table and the detail search each register this provider, so two instances
    #   are alive at once and must not unbind each other's delegated handlers.
    @eventNamespace = _.uniqueId('.ticketOverviewPopover')

  build: (buildParams) ->
    return if !@checkPermissions()

    super

    # The tip is appended to 'body', outside the table controller's element, so the
    #   handlers are delegated there instead of bound by the parent controller.
    $('body')
      .on("click#{@eventNamespace}", '.js-ticketOverviewPopoverCopyNumber', @copyNumber)
      .on("click#{@eventNamespace}", '.js-ticketOverviewPopoverSidebar', @hideOnSidebarLink)

  # Called by 'build' and when the parent controller goes away, so the handlers neither
  #   pile up nor outlive the provider that owns them.
  clear: ->
    $('body').off(@eventNamespace)

    super

  buildTitleFor: (elem) ->
    ticket = @ticketFor(elem)
    return '' if !ticket

    @buildHtmlTitle(ticket: ticket)

  # A response for a tip that already hid is of no use any more.
  onHide: (event, elem) ->
    ticket = @ticketFor(elem)
    App.Ajax.abort(@requestIdFor(ticket)) if ticket

    super

  # 'data-content' wins over 'buildContentFor', and every hide sets it to the loading
  #   placeholder, even for a tip that never showed. So a cached entry goes there on each show.
  fetch: (event, elem) ->
    ticket = @ticketFor(elem)
    return if !ticket

    cached = @cachedDataFor(ticket)
    if cached
      $(elem).attr('data-content', @renderContent(ticket, cached))
      return

    @params.parentController.ajax(
      id:          @requestIdFor(ticket)
      type:        'GET'
      url:         "#{App.Config.get('api_path')}/tickets/#{ticket.id}/popover"
      processData: true
      success:     (data) =>
        App.Collection.loadAssets(data.assets)
        @storeDataFor(ticket, data)
        @replaceOnShow(event, @renderContent(ticket, data))
    )

  ticketFor: (elem) ->
    id = $(elem).data('id')
    return if !id

    App.Ticket.find(id)

  # Scoped to the instance like the handlers, since a call with the same id aborts the
  #   one before it, and hiding a tip aborts its call.
  requestIdFor: (ticket) ->
    "ticket-overview-popover#{@eventNamespace}-#{ticket.id}"

  # Keyed by the ticket's 'updated_at', so re-hovering an unchanged row costs no request
  #   while a changed ticket is fetched again. The summary and the checklist are stored
  #   without touching the ticket, so an entry also expires on its own.
  cacheKeyFor: (ticket) ->
    "#{ticket.id}-#{ticket.updated_at}"

  cachedDataFor: (ticket) ->
    entry = @dataCache?[@cacheKeyFor(ticket)]
    return if !entry
    return if Date.now() - entry.storedAt > @constructor.dataCacheTTL

    entry.data

  storeDataFor: (ticket, data) ->
    @dataCache ||= {}
    @dataCache[@cacheKeyFor(ticket)] =
      data:     data
      storedAt: Date.now()

  renderContent: (ticket, data) ->
    @buildHtmlContent(
      ticket:    ticket
      summary:   data.summary
      articles:  @articleSections(data)
      checklist: @checklistBadge(data)
      sentiment: @sentiment(data)
    )[0].outerHTML

  # With a summary the first article is covered by the intent, so only the latest one shows.
  articleSections: (data) ->
    return [] if !data.last_article

    latest = @articleSection(__('Latest article'), data.last_article)

    return [latest] if !data.first_article
    return [latest] if data.first_article.id is data.last_article.id
    return [latest] if data.summary?.customer_request

    [@articleSection(__('First article'), data.first_article), latest]

  articleSection: (label, article) ->
    {
      label:    label
      article:  article
      author:   @authorFor(article)
      # Same side as in the ticket zoom, where the side alone tells a colleague from the customer.
      position: if article.sender is 'Customer' then 'right' else 'left'
    }

  # The assets of the response carry the author, but a cached response may outlive its records.
  authorFor: (article) ->
    return if !App.User.exists(article.author.id)

    App.User.find(article.author.id)

  # A completed checklist has nothing left to do. The setting is checked again here
  #   because a response cached before it was switched off would still carry the counts.
  checklistBadge: (data) ->
    return if !App.Config.get('checklist')
    return if !data.checklist?.total
    return if data.checklist.complete is data.checklist.total

    data.checklist

  # Exactly as the model returned it: the single word plus its emoji. Shown with the intent
  #   only, which carries the note that marks both of them as AI-generated.
  sentiment: (data) ->
    return if !App.Config.get('ai_assistance_ticket_summary_config')?.customer_sentiment
    return if !data.summary?.customer_request
    return if !data.summary?.customer_mood

    {
      emotion: data.summary.customer_emotion
      mood:    data.summary.customer_mood
    }

  # The hover tip outlives the row the link navigates away from, so it is dismissed
  #   explicitly while the navigation itself runs as usual.
  hideOnSidebarLink: =>
    @hide()

  # 'copyToClipboardWithTooltip' resolves its selector inside the parent controller's
  #   element and therefore cannot reach the tip.
  copyNumber: (event) ->
    button = $(event.currentTarget)
    text   = button.closest('.ticket-number-copy').find('.js-objectNumber').data('number')
    return if !text

    clipboard.writeText(text)

    # Bootstrap prefers an element's 'title' over the 'title' option, so the tip goes
    #   on the icon instead of the button that carries the hover title.
    icon = button.find('.ticketNumberCopy-icon')

    icon.tooltip(
      trigger:   'manual'
      placement: 'bottom'
      container: 'body'
      template:  '<div class="tooltip tooltip--abovePopover" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
      title: ->
        App.i18n.translateContent('Copied!')
    )
    icon.tooltip('show')

    App.Delay.set(->
      icon.tooltip('hide')
    , 1500)

App.PopoverProvider.registerProvider('TicketOverview', TicketOverview)
