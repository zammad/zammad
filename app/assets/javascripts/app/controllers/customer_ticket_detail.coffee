# Faithful Customer TicketDetail — matches docs/ui-references/customer-portal/.
# Dispatched from TicketZoomRouter (in ticket_zoom.coffee) when the user is
# a customer. Renders a clean threaded conversation rather than the agent
# zoom layout.
class App.CustomerTicketDetail extends App.Controller
  @requiredPermission: 'ticket.customer'

  elements:
    '.js-reply-body':   'replyInput'
    '.js-thread':       'thread'

  events:
    'click .js-back':      'onBack'
    'click .js-send':      'onSend'
    'click .js-discard':   'onDiscard'
    'click .js-resolve':   'onResolve'
    'click .js-reopen':    'onReopen'
    'input .js-reply-body':'onReplyInput'

  constructor: (params) ->
    super
    @ticket_id = params.ticket_id
    @title __('Loading…'), true

    # Defensive: TaskManager re-fires persistent tasks on route changes
    # and may invoke this controller without a ticket_id when navigating
    # away. Don't issue a /tickets/undefined?... request in that case —
    # just render an empty placeholder.
    if !@ticket_id
      @renderLoading()
      return

    @draft = ''
    @ticket_article_ids = []
    @loadTicket()

  release: =>
    super

  loadTicket: =>
    @ajax(
      id:    "customer_ticket_detail_#{@ticket_id}"
      type:  'GET'
      url:   "#{@apiPath}/tickets/#{@ticket_id}?all=true"
      processData: true
      success: (data) =>
        # /tickets/{id}?all=true returns the ticket id under .id and the
        # full asset payload under .assets — load assets so App.Ticket and
        # App.TicketArticle have records to look up.
        App.Collection.loadAssets(data.assets) if data?.assets
        @ticket_article_ids = data.article_ids or data.ticket_article_ids or []
        @ticket = App.Ticket.find(@ticket_id)
        if @ticket
          @title @ticket.title, true
          @navupdate "#ticket/zoom/#{@ticket.id}"
        @render()
      error: =>
        @notify(type: 'error', msg: __('Could not load ticket.'))
    )

  onBack: (e) =>
    e.preventDefault()
    @navigate '#ticket/view/my_tickets'

  onReplyInput: (e) =>
    @draft = e.target.value

  onDiscard: (e) =>
    e.preventDefault()
    @draft = ''
    @replyInput.val('') if @replyInput

  onSend: (e) =>
    e.preventDefault()
    return if !@draft or !@draft.trim()
    return if @sending
    @sending = true

    article = new App.TicketArticle
    article.load(
      ticket_id:   @ticket.id
      type_id:     App.TicketArticleType.findByAttribute('name', 'web')?.id
      sender_id:   App.TicketArticleSender.findByAttribute('name', 'Customer')?.id
      from:        App.Session.get().displayName()
      to:          @ticket.group?.name or ''
      subject:     ''
      body:        @draft
      content_type: 'text/plain'
      internal:    false
      form_id:     App.ControllerForm.formId()
    )
    article.save(
      done: =>
        @draft = ''
        @sending = false
        @loadTicket()
        @notify(type: 'success', msg: __('Reply sent.'))
      fail: (settings, details) =>
        @sending = false
        @notify(type: 'error', msg: details?.error_human or __('Could not send reply.'))
    )

  onResolve: (e) =>
    e.preventDefault()
    @updateState('closed')

  onReopen: (e) =>
    e.preventDefault()
    @updateState('open')

  updateState: (stateName) =>
    state = App.TicketState.findByAttribute('name', stateName)
    return if !state
    ticket = App.Ticket.find(@ticket.id)
    ticket.state_id = state.id
    ticket.save(
      done: =>
        @loadTicket()
        @notify(type: 'success', msg: __('Ticket updated.'))
    )

  relTime: (iso) ->
    return '' if !iso
    d = new Date(iso)
    d.toLocaleString(undefined, month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit')

  bucketFor: (ticket) ->
    state = if ticket then App.TicketState.find(ticket.state_id) else null
    stateType = if state then App.TicketStateType.find(state.state_type_id) else null
    return 'closed' if state?.name in ['closed', 'merged']
    return 'pending'  if stateType?.name in ['pending reminder', 'pending action']
    return 'resolved' if stateType?.name is 'closed'
    'open'

  authorOf: (article) ->
    sender = if article.sender_id then App.TicketArticleSender.find(article.sender_id) else null
    isAgent = sender?.name is 'Agent' or sender?.name is 'System'
    user = if article.created_by_id then App.User.find(article.created_by_id) else null
    {
      isAgent: !!isAgent
      name:    user?.fullname or article.from or (if isAgent then __('Support') else __('You'))
    }

  decoratedArticles: ->
    return [] if !@ticket_article_ids or @ticket_article_ids.length is 0
    rows = []
    for id in @ticket_article_ids
      a = App.TicketArticle.find(id)
      continue if !a
      who = @authorOf(a)
      rows.push
        id:            a.id
        body:          a.body
        internal:      a.internal
        created_at:    a.created_at
        isAgent:       who.isAgent
        displayAuthor: who.name
    rows

  render: =>
    return @renderLoading() if !@ticket

    bucket = @bucketFor(@ticket)
    state  = App.TicketState.find(@ticket.state_id)
    priority = App.TicketPriority.find(@ticket.priority_id)
    group  = App.Group.find(@ticket.group_id)
    articles = @decoratedArticles()

    @html App.view('customer_ticket_detail')(
      ticket:        @ticket
      number:        @ticket.number
      title:         @ticket.title
      bucket:        bucket
      stateName:     state?.name
      priorityName:  priority?.name or 'normal'
      groupName:     group?.name or ''
      createdAt:     @relTime(@ticket.created_at)
      articles:      articles
      draft:         @draft
      isResolved:    bucket is 'resolved'
      isClosed:      bucket is 'closed'
      relTime:       (iso) => @relTime(iso)
      pillClass:     "cp-pill cp-pill--#{bucket}"
      priClass:      (->
        if /high|3/i.test(priority?.name or '') then 'cp-pri cp-pri--high'
        else if /low|1/i.test(priority?.name or '') then 'cp-pri cp-pri--low'
        else 'cp-pri cp-pri--normal'
      )()
    )

  renderLoading: =>
    @html '<div class="cp-empty" style="padding:60px 28px;">' + App.i18n.translateContent('Loading…') + '</div>'

App.Config.set('CustomerTicketDetail', { controller: 'CustomerTicketDetail', permission: ['ticket.customer'] }, 'permanentTask')
