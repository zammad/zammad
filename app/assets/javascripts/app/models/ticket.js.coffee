class App.Ticket extends App.Model
  @configure 'Ticket', 'number', 'title', 'group_id', 'owner_id', 'customer_id', 'state_id', 'priority_id', 'article', 'tags', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/tickets'
  @configure_attributes = [
      { name: 'number',                display: '#',        tag: 'input',    type: 'text', limit: 100, null: true, read_only: true,  style: 'width: 8%'  },
      { name: 'customer_id',           display: 'Customer', tag: 'input',    type: 'text', limit: 100, null: false, autocapitalize: false, relation: 'User' },
      { name: 'organization_id',       display: 'Organization', relation: 'Organization', tagreadonly: 1 },
      { name: 'group_id',              display: 'Group',    tag: 'select',   multiple: false, limit: 100, null: false, relation: 'Group', style: 'width: 10%', edit: true },
      { name: 'owner_id',              display: 'Owner',    tag: 'select',   multiple: false, limit: 100, null: true, relation: 'User', style: 'width: 12%', edit: true },
      { name: 'title',                 display: 'Title',    tag: 'input',    type: 'text', limit: 100, null: false, parentClass: 'noTruncate' },
      { name: 'state_id',              display: 'State',    tag: 'select',   multiple: false, null: false, relation: 'TicketState', default: 'new', style: 'width: 12%', edit: true, customer: true, },
      { name: 'priority_id',           display: 'Priority', tag: 'select',   multiple: false, null: false, relation: 'TicketPriority', default: '2 normal', style: 'width: 12%', edit: true, customer: true, },
      { name: 'last_contact',          display: 'Last contact',            type: 'time', null: true, style: 'width: 12%', parentClass: 'noTruncate' },
      { name: 'last_contact_agent',    display: 'Last contact (Agent)',    type: 'time', null: true, style: 'width: 12%', parentClass: 'noTruncate' },
      { name: 'last_contact_customer', display: 'Last contact (Customer)', type: 'time', null: true, style: 'width: 12%', parentClass: 'noTruncate' },
      { name: 'first_response',        display: 'First response',          type: 'time', null: true, style: 'width: 12%', parentClass: 'noTruncate' },
      { name: 'close_time',            display: 'Close time',              type: 'time', null: true, style: 'width: 12%', parentClass: 'noTruncate' },
      { name: 'escalation_time',       display: 'Escalation',              type: 'time', null: true, style: 'width: 12%', class: 'escalation', parentClass: 'noTruncate' },
      { name: 'article_count',         display: 'Article#',  style: 'width: 12%' },
      { name: 'created_by_id',         display: 'Created by', relation: 'User', readonly: 1 },
      { name: 'created_at',            display: 'Created', type: 'time', style: 'width: 120px', readonly: 1, parentClass: 'noTruncate' },
      { name: 'updated_by_id',         display: 'Updated by', relation: 'User', readonly: 1 },
      { name: 'updated_at',            display: 'Updated', type: 'time', style: 'width: 120px', readonly: 1, parentClass: 'noTruncate' },
    ]

  uiUrl: ->
    '#ticket/zoom/' + @id

  level: (user) ->
    state = App.TicketState.find( @state_id )
    level = 1
    if state.name is 'new' || state.name is 'open'
      level = 2
    else if state.name is 'pending'
      level = 3
    level

  icon: (user) ->
    "priority icon level-#{ @level() }"

  iconTitle: (user) ->
    App.TicketState.find( @state_id ).displayName()

  iconActivity: (user) ->
    if @owner_id == user.id
      return 'important'
    ''