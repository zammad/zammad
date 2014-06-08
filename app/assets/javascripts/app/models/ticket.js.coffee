class App.Ticket extends App.Model
  @configure 'Ticket', 'number', 'title', 'group_id', 'owner_id', 'customer_id', 'state_id', 'priority_id', 'article', 'tags', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/tickets'
  @configure_attributes = [
      { name: 'number',                display: '#',        tag: 'input',    type: 'text', limit: 100, null: true, read_only: true,  style: 'width: 8%'  },
      { name: 'customer_id',           display: 'Customer', tag: 'input',    type: 'text', limit: 100, null: false, class: 'span8', autocapitalize: false, help: 'Select the customer of the Ticket or create one.', link: '<a href="" class="customer_new">&raquo;</a>' },
      { name: 'group_id',              display: 'Group',    tag: 'select',   multiple: false, limit: 100, null: false, class: 'span8', relation: 'Group', style: 'width: 10%' },
      { name: 'owner_id',              display: 'Owner',    tag: 'select',   multiple: false, limit: 100, null: true, class: 'span8', relation: 'User', style: 'width: 12%' },
      { name: 'title',                 display: 'Title',    tag: 'input',    type: 'text', limit: 100, null: false, class: 'span8' },
      { name: 'state_id',              display: 'State',    tag: 'select',   multiple: false, null: false, relation: 'TicketState', default: 'new', class: 'medium', style: 'width: 12%' },
      { name: 'priority_id',           display: 'Priority', tag: 'select',   multiple: false, null: false, relation: 'TicketPriority', default: '2 normal', class: 'medium', style: 'width: 12%' },
      { name: 'created_at',            display: 'Created',  tag: 'time', style: 'width: 12%' },
      { name: 'last_contact',          display: 'Last contact',            tag: 'time', null: true, style: 'width: 12%' },
      { name: 'last_contact_agent',    display: 'Last contact (Agent)',    tag: 'time', null: true, style: 'width: 12%' },
      { name: 'last_contact_customer', display: 'Last contact (Customer)', tag: 'time', null: true, style: 'width: 12%' },
      { name: 'first_response',        display: 'First response',          tag: 'time', null: true, style: 'width: 12%' },
      { name: 'close_time',            display: 'Close time',              tag: 'time', null: true, style: 'width: 12%' },
      { name: 'escalation_time',       display: 'Escalation in',           tag: 'time', null: true, style: 'width: 12%' },
      { name: 'article_count',         display: 'Article#',  style: 'width: 12%' },
    ]

  uiUrl: ->
    '#ticket/zoom/' + @id

  @_fillUp: (data) ->

    # priority
    data.priority = App.TicketPriority.find( data.priority_id )

    # state
    data.state = App.TicketState.find( data.state_id )

    # group
    data.group = App.Group.find( data.group_id )

    # customer
    if data.customer_id
      if !App.User.exists( data.customer_id )
        console.error("Can't find user for data.customer_id #{data.customer_id} for ticket #{data.id}")
      else
        data.customer = App.User.find( data.customer_id )

    # owner
    if data.owner_id
      if !App.User.exists( data.owner_id )
        console.error("Can't find user for data.owner_id #{data.owner_id} for ticket #{data.id}")
      else
        data.owner = App.User.find( data.owner_id )

    # add created & updated
    if data.created_by_id
      if !App.User.exists( data.created_by_id )
        console.error("Can't find user for data.created_by_id #{data.created_by_id} for ticket #{data.id}")
      else
        data.created_by = App.User.find( data.created_by_id )
    if data.updated_by_id
      if !App.User.exists( data.updated_by_id )
        console.error("Can't find user for data.updated_by_id #{data.updated_by_id} for ticket #{data.id}")
      else
        data.updated_by = App.User.find( data.updated_by_id )

    data

