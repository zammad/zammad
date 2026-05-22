# Faithful Customer NewTicket — matches docs/ui-references/customer-portal/.
# Replaces the prior ControllerForm-wrapped layout with an explicit
# Subject / Category / Priority / Description / Attachments form.
class CustomerTicketCreate extends App.ControllerAppContent
  @requiredPermission: 'ticket.customer'

  events:
    'submit form':            'submit'
    'click .js-submit':       'submit'
    'click .js-cancel':       'cancel'
    'click .js-priority-opt': 'onPriorityChange'
    'change .js-file':        'onFiles'

  constructor: (params) ->
    super
    @authenticateCheckRedirect()

    @title __('New Ticket')
    @navupdate '#customer_ticket_new'

    @form_id     = App.ControllerForm.formId()
    @priority    = 'normal'
    @attachments = []
    @errors      = {}

    # Customers see only the groups they're allowed to create tickets in.
    # If no groups are returned by the API, fall back to the local Group
    # collection so the picker still has options to choose from.
    @groups = App.Group.search(filter: { active: true })
    @render()

    @ajax(
      type: 'GET'
      url:  "#{@apiPath}/ticket_create"
      processData: true
      success: (data) =>
        App.Collection.loadAssets(data.assets) if data?.assets
        @groups = App.Group.search(filter: { active: true })
        @render()
    )

  onPriorityChange: (e) =>
    e.preventDefault()
    @priority = $(e.currentTarget).data('priority')
    @el.find('.js-priority-opt').removeClass('cp-seg-btn--on')
    $(e.currentTarget).addClass('cp-seg-btn--on')

  onFiles: (e) =>
    files = Array.from(e.target.files or [])
    return if !files.length
    for f in files
      @attachments.push(name: f.name, size: @formatSize(f.size), kind: (if f.type?.startsWith('image/') then 'image' else 'file'), file: f)
    @renderAttachments()
    e.target.value = ''

  formatSize: (bytes) ->
    return '' if !bytes
    if bytes < 1024 then "#{bytes} B"
    else if bytes < 1024 * 1024 then "#{Math.round(bytes / 1024)} KB"
    else "#{(bytes / 1024 / 1024).toFixed(1)} MB"

  removeAttachment: (e) =>
    e.preventDefault()
    idx = parseInt($(e.currentTarget).data('idx'), 10)
    @attachments.splice(idx, 1)
    @renderAttachments()

  cancel: (e) =>
    e?.preventDefault()
    @navigate '#dashboard'

  render: =>
    priorities = ['low', 'normal', 'high']
    @html App.view('customer_ticket_create_faithful')(
      form_id:     @form_id
      groups:      @groups
      priorities:  priorities
      priority:    @priority
      attachments: @attachments
      errors:      @errors
    )

  renderAttachments: =>
    container = @el.find('.js-attachments')
    return if !container.length
    container.html App.view('customer_ticket_create_attachments')(attachments: @attachments)
    container.find('.js-remove-attach').on('click', @removeAttachment)

  submit: (e) =>
    e.preventDefault()

    title  = @el.find('[name="title"]').val()
    groupId = @el.find('[name="group_id"]').val()
    body   = @el.find('[name="body"]').val()

    @errors = {}
    @errors.title = __('Give your ticket a short title.') if !title or !title.trim()
    @errors.body  = __('Describe what is happening so we can help.') if !body or !body.trim()

    if !_.isEmpty(@errors)
      @render()
      return

    priorityRecord = App.TicketPriority.findByAttribute('name', '2 normal') or App.TicketPriority.findByAttribute('default_create', true)
    if @priority is 'high'
      priorityRecord = App.TicketPriority.findByAttribute('name', '3 high') or priorityRecord
    else if @priority is 'low'
      priorityRecord = App.TicketPriority.findByAttribute('name', '1 low') or priorityRecord

    state = App.TicketState.findByAttribute('default_create', true) or App.TicketState.findByAttribute('name', 'new')
    sender = App.TicketArticleSender.findByAttribute('name', 'Customer')
    type   = App.TicketArticleType.findByAttribute('name', 'web')

    params =
      title:       title.trim()
      group_id:    groupId
      customer_id: @Session.get('id')
      state_id:    state?.id
      priority_id: priorityRecord?.id
      article:
        from:         @Session.get().displayName()
        to:           (App.Group.find(groupId)?.name or '')
        subject:      title.trim()
        body:         body.trim()
        type_id:      type?.id
        sender_id:    sender?.id
        form_id:      @form_id
        content_type: 'text/plain'
        internal:     false

    ticket = new App.Ticket
    ticket.load(params)
    @el.find('.js-submit').prop('disabled', true)
    ticket.save(
      done: =>
        @navigate '#ticket/view/my_tickets'
      fail: (settings, details) =>
        @el.find('.js-submit').prop('disabled', false)
        @notify(type: 'error', msg: details?.error_human or details?.error or __('The object could not be created.'))
    )

App.Config.set('customer_ticket_new', CustomerTicketCreate, 'Routes')
App.Config.set('CustomerTicketNew', {
  prio: 8003,
  parent: '#new',
  name: __('New Ticket'),
  translate: true,
  target: '#customer_ticket_new',
  permission: (navigation) ->
    return false if navigation.permissionCheck('ticket.agent')
    return navigation.permissionCheck('ticket.customer')
  setting: ['customer_ticket_create'],
  divider: true
}, 'NavBarRight')
