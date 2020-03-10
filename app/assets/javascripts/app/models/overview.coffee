class App.Overview extends App.Model
  @configure 'Overview', 'name', 'prio', 'condition', 'order', 'group_by', 'group_direction', 'view', 'user_ids', 'organization_shared', 'out_of_office', 'role_ids', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/overviews'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',    type: 'text', limit: 100, 'null': false },
    { name: 'link',       display: 'Link',                readonly: 1 },
    { name: 'role_ids',   display: 'Available for the following roles',    tag: 'column_select', multiple: true, null: false, relation: 'Role', translate: true },
    { name: 'user_ids',   display: 'Restrict to only the following users', tag: 'column_select', multiple: true, null: true,  relation: 'User', sortBy: 'firstname' },
    { name: 'organization_shared', display: 'Only available for Users with shared Organization', tag: 'select', options: { true: 'yes', false: 'no' }, default: false, null: true },
    { name: 'out_of_office', display: 'Only available for Users which are replacements for other users.', tag: 'select', options: { true: 'yes', false: 'no' }, default: false, null: true },
    { name: 'condition',  display: 'Conditions for shown Tickets', tag: 'ticket_selector', null: false, out_of_office: true },
    { name: 'prio',       display: 'Prio',                readonly: 1 },
    {
      name:    'view::s'
      display: 'Attributes'
      tag:     'checkboxTicketAttributes'
      default: ['number', 'title', 'state', 'created_at']
      null:    false
      translate: true
    },
    {
      name:    'order::by',
      display: 'Order',
      tag:     'selectTicketAttributes'
      default: 'created_at'
      null:    false
      translate: true
    },
    {
      name:    'order::direction'
      display: 'Order by Direction'
      tag:     'select'
      default: 'down'
      null:    false
      translate: true
      options:
        ASC:   'up'
        DESC:  'down'
    },
    {
      name:    'group_by'
      display: 'Group by'
      tag:     'select'
      default: ''
      null:    true
      nulloption: true
      translate:  true
      options:
        customer:               'Customer'
        state:                  'State'
        priority:               'Priority'
        group:                  'Group'
        owner:                  'Owner'
    },
    {
      name:    'group_direction'
      display: 'Group by Direction'
      tag:     'select'
      default: 'down'
      null:    false
      translate: true
      options:
        ASC:   'up'
        DESC:  'down'
    },
    { name: 'active',         display: 'Active',      tag: 'active', default: true },
    { name: 'created_by_id',  display: 'Created by',  relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',     tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',  relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',     tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'link',
    'role_ids',
  ]

  @description = '''
You can create **overviews** for your agents and your customers. These could for instance serve as a sort of work list for items for which your agents would work.

You can also create overviews and limit them to specific agents or to groups of agents.
'''

  uiUrl: ->
    "#ticket/view/#{@link}"

  tickets: =>
    App.OverviewListCollection.get(@link).tickets

  indexOf: (ticket) =>
    # coerce id to Ticket object
    ticket = App.Ticket.find(ticket) if !(isNaN ticket)
    _.findIndex(@tickets(), (t) -> t.id == ticket.id)

  nextTicket: (thisTicket) =>
    thisIndex = @indexOf(thisTicket)
    if thisIndex >= 0 then @tickets()[thisIndex + 1] else undefined

  prevTicket: (thisTicket) =>
    @tickets()[@indexOf(thisTicket) - 1]

  @groupByAttributes: ->
    groupByAttributes = {}
    for key, attribute of App.Ticket.attributesGet()
      if !key.match(/(_at|_no)$/) && attribute.tag isnt 'datetime' && key isnt 'number' && key isnt 'tags'
        key = key.replace(/_(id|ids)$/, '')
        groupByAttributes[key] = attribute.display
    groupByAttributes
