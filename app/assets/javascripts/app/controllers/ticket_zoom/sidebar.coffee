class Edit extends App.ObserverController
  model: 'Ticket'
  observeNot:
    created_at: true
    updated_at: true

  render: (ticket, diff) =>
    defaults = ticket.attributes()
    delete defaults.article # ignore article infos
    taskState = @taskGet('ticket')

    if !_.isEmpty(taskState)
      defaults = _.extend(defaults, taskState)

    form = new App.ControllerForm(
      model:    App.Ticket
      screen:   'edit'
      handlers: [
        @ticketFormChanges
      ]
      filter:    @formMeta.filter
      params:    defaults
      #bookmarkable: true
    )
    @html form.html()

    @markForm(true)

    return if @resetBind
    @resetBind = true
    @bind('ui::ticket::taskReset', (data) =>
      return if data.ticket_id isnt ticket.id
      @render(ticket)
    )

class App.TicketZoomSidebar extends App.ObserverController
  model: 'Ticket'
  observe:
    customer_id: true
    organization_id: true

  render: (ticket) =>

    editTicket = (el) =>
      el.append('<form><fieldset class="edit"></fieldset></form><div class="tags"></div><div class="links"></div>')

      @edit = new Edit(
        object_id: ticket.id
        el:        el.find('.edit')
        taskGet:   @taskGet
        formMeta:  @formMeta
        markForm:  @markForm
      )

      if !@isRole('Customer')
        @tagWidget = new App.WidgetTag(
          el:          @el.find('.tags')
          object_type: 'Ticket'
          object:      ticket
          tags:        @tags
        )
        @linkWidget = new App.WidgetLink(
          el:          @el.find('.links')
          object_type: 'Ticket'
          object:      ticket
          links:       @links
        )

    showTicketHistory = =>
      new App.TicketHistory(
        ticket_id: ticket.id
        container: @el.closest('.content')
      )
    showTicketMerge = =>
      new App.TicketMerge(
        ticket:    ticket
        task_key:  @task_key
        container: @el.closest('.content')
      )
    changeCustomer = (e, el) =>
      new App.TicketCustomer(
        ticket:    ticket
        container: @el.closest('.content')
      )
    @sidebarItems = [
      {
        head:     'Ticket'
        name:     'ticket'
        icon:     'message'
        callback: editTicket
      }
    ]
    if !@isRole('Customer')
      @sidebarItems[0]['actions'] = [
        {
          name:     'ticket-history'
          title:    'History'
          callback: showTicketHistory
        },
        {
          name:     'ticket-merge'
          title:    'Merge'
          callback: showTicketMerge
        },
        {
          title:    'Change Customer'
          name:     'customer-change'
          callback: changeCustomer
        },
      ]
    if !@isRole('Customer')
      editCustomer = (e, el) =>
        new App.ControllerGenericEdit(
          id: ticket.customer_id
          genericObject: 'User'
          screen: 'edit'
          pageData:
            title:   'Users'
            object:  'User'
            objects: 'Users'
          container: @el.closest('.content')
        )
      showCustomer = (el) ->
        new App.WidgetUser(
          el:       el
          user_id:  ticket.customer_id
        )
      @sidebarItems.push {
        head:    'Customer'
        name:    'customer'
        icon:    'person'
        actions: [
          {
            title:    'Change Customer'
            name:     'customer-change'
            callback: changeCustomer
          },
          {
            title:    'Edit Customer'
            name:     'customer-edit'
            callback: editCustomer
          },
        ]
        callback: showCustomer
      }
      if ticket.organization_id
        editOrganization = (e, el) =>
          new App.ControllerGenericEdit(
            id: ticket.organization_id,
            genericObject: 'Organization'
            pageData:
              title:   'Organizations'
              object:  'Organization'
              objects: 'Organizations'
            container: @el.closest('.content')
          )
        showOrganization = (el) ->
          new App.WidgetOrganization(
            el:              el
            organization_id: ticket.organization_id
          )
        @sidebarItems.push {
          head: 'Organization'
          name: 'organization'
          icon: 'group'
          actions: [
            {
              title:    'Edit Organization'
              name:     'organization-edit'
              callback: editOrganization
            },
          ]
          callback: showOrganization
        }
    new App.Sidebar(
      el:           @el.find('.tabsSidebar')
      sidebarState: @sidebarState
      items:        @sidebarItems
    )
