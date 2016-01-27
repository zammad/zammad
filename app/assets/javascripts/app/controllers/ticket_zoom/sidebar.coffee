class App.TicketZoomSidebar extends App.Controller
  constructor: ->
    super
    ticket       = App.Ticket.fullLocal(@ticket.id)
    @subscribeId = ticket.subscribe(@render)
    @render(ticket)

  release: =>
    App.Ticket.unsubscribe(@subscribeId)

  render: (ticket) =>

    editTicket = (el) =>
      el.append('<form class="edit"></form>')
      @editEl = el

      show = (ticket) =>
        el.find('.edit').html('')

        defaults   = ticket.attributes()
        task_state = @taskGet('ticket')
        modelDiff  = App.Utils.formDiff(task_state, defaults)
        #if @isRole('Customer')
        #  delete defaults['state_id']
        #  delete defaults['state']
        if !_.isEmpty(task_state)
          defaults = _.extend(defaults, task_state)

        new App.ControllerForm(
          el:       el.find('.edit')
          model:    App.Ticket
          screen:   'edit'
          handlers: [
            @ticketFormChanges
          ]
          filter:    @formMeta.filter
          params:    defaults
          #bookmarkable: true
        )
        #console.log('Ichanges', modelDiff, task_state, ticket.attributes())
        #@markFormDiff( modelDiff )

      show(ticket)
      @bind(
        'ui::ticket::taskReset'
        (data) ->
          if data.ticket_id is ticket.id
            show(ticket)
      )

      if !@isRole('Customer')
        el.append('<div class="tags"></div>')
        @tagWidget = new App.WidgetTag(
          el:          el.find('.tags')
          object_type: 'Ticket'
          object:      ticket
          tags:        @tags
        )
        el.append('<div class="links"></div>')
        @linkWidget = new App.WidgetLink(
          el:          el.find('.links')
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
      el:           @el
      sidebarState: @sidebarState
      items:        @sidebarItems
    )
