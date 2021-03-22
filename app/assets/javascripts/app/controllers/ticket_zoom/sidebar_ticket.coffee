class Edit extends App.ControllerObserver
  model: 'Ticket'
  observeNot:
    created_at: true
    updated_at: true
  globalRerender: false

  render: (ticket, diff) =>
    defaults = ticket.attributes()
    delete defaults.article # ignore article infos
    followUpPossible = App.Group.find(defaults.group_id).follow_up_possible
    ticketState = App.TicketState.find(defaults.state_id).name

    taskState = @taskGet('ticket')
    handlers = @Config.get('TicketZoomFormHandler')

    if !_.isEmpty(taskState)
      defaults = _.extend(defaults, taskState)

    if followUpPossible == 'new_ticket' && ticketState != 'closed' ||
       followUpPossible != 'new_ticket' ||
       @permissionCheck('admin') || ticket.currentView() is 'agent'
      new App.ControllerForm(
        elReplace:      @el
        model:          { className: 'Ticket', configure_attributes: @formMeta.configure_attributes || App.Ticket.configure_attributes }
        screen:         'edit'
        handlersConfig: handlers
        filter:         @formMeta.filter
        formMeta:       @formMeta
        params:         defaults
        isDisabled:     !ticket.editable()
        taskKey:        @taskKey
        #bookmarkable:  true
      )
    else
      new App.ControllerForm(
        elReplace:      @el
        model:          { configure_attributes: @formMeta.configure_attributes || App.Ticket.configure_attributes }
        screen:         'edit'
        handlersConfig: handlers
        filter:         @formMeta.filter
        formMeta:       @formMeta
        params:         defaults
        isDisabled:     ticket.editable()
        taskKey:        @taskKey
        #bookmarkable:  true
      )

    @markForm(true)

    return if @resetBind
    @resetBind = true
    @controllerBind('ui::ticket::taskReset', (data) =>
      return if data.ticket_id.toString() isnt ticket.id.toString()
      @render(ticket)
    )

class SidebarTicket extends App.Controller
  constructor: ->
    super
    @controllerBind('config_update_local', (data) => @configUpdated(data))

  configUpdated: (data) ->
    if data.name != 'kb_active'
      return

    if data.value
      return

    @editTicket(@el)

  sidebarItem: =>
    @item = {
      name: 'ticket'
      badgeIcon: 'message'
      sidebarHead: 'Ticket'
      sidebarCallback: @editTicket
    }
    if @ticket.currentView() is 'agent'
      @item.sidebarActions = [
        {
          title:    'History'
          name:     'ticket-history'
          callback: @showTicketHistory
        },
        {
          title:    'Merge'
          name:     'ticket-merge'
          callback: @showTicketMerge
        },
        {
          title:    'Change Customer'
          name:     'customer-change'
          callback: @changeCustomer
        },
      ]
    @item

  reload: (args) =>

    # apply tag changes
    if @tagWidget
      if args.tags
        @tagWidget.reload(args.tags)
      if args.mentions
        @mentionWidget.reload(args.mentions)
      if args.tagAdd
        @tagWidget.add(args.tagAdd, args.source)
      if args.tagRemove
        @tagWidget.remove(args.tagRemove)

    # apply link changes
    if @linkWidget && args.links
      @linkWidget.reload(args.links)

    if @linkKbAnswerWidget && args.links
      @linkKbAnswerWidget.reload(args.links)

  editTicket: (el) =>
    @el = el
    localEl = $(App.view('ticket_zoom/sidebar_ticket')())

    @edit = new Edit(
      object_id: @ticket.id
      el:        localEl.find('.edit')
      taskGet:   @taskGet
      formMeta:  @formMeta
      markForm:  @markForm
      taskKey:   @taskKey
    )

    if @ticket.currentView() is 'agent'
      @mentionWidget = new App.WidgetMention(
        el:       localEl.filter('.js-subscriptions')
        object:   @ticket
        mentions: @mentions
      )
      @tagWidget = new App.WidgetTag(
        el:          localEl.filter('.js-tags')
        object_type: 'Ticket'
        object:      @ticket
        tags:        @tags
      )
      @linkWidget = new App.WidgetLink.Ticket(
        el:          localEl.filter('.js-links')
        object_type: 'Ticket'
        object:      @ticket
        links:       @links
      )

      if @permissionCheck('knowledge_base.*') and App.Config.get('kb_active')
        @linkKbAnswerWidget = new App.WidgetLinkKbAnswer(
          el:          localEl.filter('.js-linkKbAnswers')
          object_type: 'Ticket'
          object:      @ticket
          links:       @links
        )

      @timeUnitWidget = new App.TicketZoomTimeUnit(
        el:        localEl.filter('.js-timeUnit')
        object_id: @ticket.id
      )
    @html localEl

  showTicketHistory: =>
    new App.TicketHistory(
      ticket_id: @ticket.id
      container: @el.closest('.content')
    )

  showTicketMerge: =>
    new App.TicketMerge(
      ticket:    @ticket
      taskKey:   @taskKey
      container: @el.closest('.content')
    )

  changeCustomer: =>
    new App.TicketCustomer(
      ticket_id: @ticket.id
      container: @el.closest('.content')
    )

App.Config.set('100-TicketEdit', SidebarTicket, 'TicketZoomSidebar')
