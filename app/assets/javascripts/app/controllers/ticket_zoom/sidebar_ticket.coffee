# No usage of a ControllerObserver here because we want to use
# the data of the ticket zoom ajax request which is using the all=true parameter
# and contain the core workflow information as well. Without observer we also
# dont have double rendering because of the zoom (all=true) and observer (full=true) render callback
class Edit extends App.Controller
  constructor: (params) ->
    super
    @controllerBind('ui::ticket::load', (data) =>
      return if data.ticket_id.toString() isnt @ticket.id.toString()

      @ticket   = App.Ticket.find(@ticket.id)
      if data.form_meta
        @formMeta = data.form_meta
      @render(data.draft)
    )
    @render()

  render: (draft = {}) =>
    defaults = @ticket.attributes()
    delete defaults.article # ignore article infos

    taskState = @taskGet('ticket')
    handlers = @Config.get('TicketZoomFormHandler')

    if !_.isEmpty(taskState)
      defaults = _.extend(defaults, taskState)
      # remove core workflow data because it should trigger a request to get data
      # for the new ticket + eventually changed task state
      @formMeta.core_workflow = undefined

    # reset updated_at for the sidbar because we render a new state
    # it is used to compare the ticket with the rendered data later
    # and needed to prevent race conditions
    @el.removeAttr('data-ticket-updated-at')

    @controllerFormSidebarTicket = new App.ControllerForm(
      elReplace:      @el
      model:          { className: 'Ticket', configure_attributes: @formMeta.configure_attributes || App.Ticket.configure_attributes }
      screen:         'edit'
      handlersConfig: handlers
      filter:         @formMeta.filter
      formMeta:       @formMeta
      params:         _.extend(defaults, draft)
      isDisabled:     @isDisabledByFollowupRules(defaults)
      taskKey:        @taskKey
      core_workflow: {
        callbacks: [@markForm]
      }
      #bookmarkable:  true
    )

    # set updated_at for the sidbar because we render a new state
    @el.attr('data-ticket-updated-at', defaults.updated_at)
    @markForm(true)

    return if @resetBind
    @resetBind = true
    @controllerBind('ui::ticket::taskReset', (data) =>
      return if data.ticket_id.toString() isnt @ticket.id.toString()
      @render()
    )

  isDisabledByFollowupRules: (attributes) =>
    return false if @ticket.userGroupAccess('change')

    group           = App.Group.find(attributes.group_id)
    ticketStateType = App.TicketState.find(attributes.state_id).name
    initialState    = !@ticket.editable()

    return initialState if ticketStateType isnt 'closed'

    switch group.follow_up_possible
      when 'yes'
        return initialState
      when 'new_ticket'
        return true
      when 'new_ticket_after_certain_time'
        closed_since = (new Date - Date.parse(@ticket.last_close_at)) / (24 * 60 * 60 * 1000)

        return closed_since >= group.reopen_time_in_days

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
      sidebarHead: __('Ticket')
      sidebarCallback: @editTicket
    }
    if @ticket.currentView() is 'agent'
      @item.sidebarActions = []
      @item.sidebarActions.push(
        title:    __('History')
        name:     'ticket-history'
        callback: @showTicketHistory
      )
      if @ticket.editable()
        @item.sidebarActions.push(
          title:    __('Merge')
          name:     'ticket-merge'
          callback: @showTicketMerge
        )
        @item.sidebarActions.push(
          title:    __('Change Customer')
          name:     'customer-change'
          callback: @changeCustomer
        )
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
      ticket:    @ticket
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
        editable:    @ticket.editable()
      )
      @linkWidget = new App.WidgetLink.Ticket(
        el:          localEl.filter('.js-links')
        object_type: 'Ticket'
        object:      @ticket
        links:       @links
        editable:    @ticket.editable()
      )

      if @permissionCheck('knowledge_base.*') and App.Config.get('kb_active')
        @linkKbAnswerWidget = new App.WidgetLinkKbAnswer(
          el:          localEl.filter('.js-linkKbAnswers')
          object_type: 'Ticket'
          object:      @ticket
          links:       @links
          editable:    @ticket.editable()
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
