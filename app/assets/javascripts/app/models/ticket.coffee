class App.Ticket extends App.Model
  @configure 'Ticket', 'number', 'title', 'group_id', 'owner_id', 'customer_id', 'state_id', 'priority_id', 'article', 'tags', 'links', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/tickets'
  @configure_attributes = [
      { name: 'number',                   display: '#',            tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1, width: '68px' },
      { name: 'title',                    display: 'Title',        tag: 'input',    type: 'text', limit: 100, null: false },
      { name: 'customer_id',              display: 'Customer',     tag: 'input',    type: 'text', limit: 100, null: false, autocapitalize: false, relation: 'User' },
      { name: 'organization_id',          display: 'Organization', tag: 'select',   relation: 'Organization', readonly: 1 },
      { name: 'group_id',                 display: 'Group',        tag: 'select',   multiple: false, limit: 100, null: false, relation: 'Group', width: '10%', edit: true },
      { name: 'owner_id',                 display: 'Owner',        tag: 'select',   multiple: false, limit: 100, null: true, relation: 'User', width: '12%', edit: true },
      { name: 'state_id',                 display: 'State',        tag: 'select',   multiple: false, null: false, relation: 'TicketState', default: 'new', width: '12%', edit: true, customer: true },
      { name: 'pending_time',             display: 'Pending Time', tag: 'datetime', null: true, width: '130px' },
      { name: 'priority_id',              display: 'Priority',     tag: 'select',   multiple: false, null: false, relation: 'TicketPriority', default: '2 normal', width: '12%', edit: true, customer: true },
      { name: 'article_count',            display: 'Article#',     readonly: 1, width: '12%' },
      { name: 'escalation_at',            display: 'Escalation',              tag: 'datetime', null: true, readonly: 1, width: '110px', class: 'escalation' },
      { name: 'last_contact_at',          display: 'Last contact',            tag: 'datetime', null: true, readonly: 1, width: '110px' },
      { name: 'last_contact_agent_at',    display: 'Last contact (Agent)',    tag: 'datetime', null: true, readonly: 1, width: '110px' },
      { name: 'last_contact_customer_at', display: 'Last contact (Customer)', tag: 'datetime', null: true, readonly: 1, width: '110px' },
      { name: 'first_response_at',        display: 'First response',          tag: 'datetime', null: true, readonly: 1, width: '110px' },
      { name: 'close_at',                 display: 'Close time',              tag: 'datetime', null: true, readonly: 1, width: '110px' },
      { name: 'created_by_id',            display: 'Created by',   relation: 'User', readonly: 1 },
      { name: 'created_at',               display: 'Created at',   tag: 'datetime', width: '110px', align: 'right', readonly: 1 },
      { name: 'updated_by_id',            display: 'Updated by',   relation: 'User', readonly: 1 },
      { name: 'updated_at',               display: 'Updated at',   tag: 'datetime', width: '110px', align: 'right', readonly: 1 },
    ]

  uiUrl: ->
    '#ticket/zoom/' + @id

  getState: ->
    type = App.TicketState.find(@state_id)
    stateType = App.TicketStateType.find(type.state_type_id)
    state = 'closed'
    if stateType.name is 'new' || stateType.name is 'open'
      state = 'open'

      # if ticket is escalated, overwrite state
      if @escalation_at && new Date( Date.parse(@escalation_at) ) < new Date
        state = 'escalating'
    else if stateType.name is 'pending reminder'
      state = 'pending'

      # if ticket pending_time is reached, overwrite state
      if @pending_time && new Date( Date.parse(@pending_time) ) < new Date
        state = 'open'
    else if stateType.name is 'pending action'
      state = 'pending'
    state

  icon: ->
    'task-state'

  iconClass: ->
    @getState()

  iconTitle: ->
    type = App.TicketState.find(@state_id)
    stateType = App.TicketStateType.find(type.state_type_id)
    if stateType.name is 'pending reminder' && @pending_time && new Date( Date.parse(@pending_time) ) < new Date
      return "#{App.i18n.translateInline(type.displayName())} - #{App.i18n.translateInline('reached')}"
    if @escalation_at && new Date( Date.parse(@escalation_at) ) < new Date
      return "#{App.i18n.translateInline(type.displayName())} - #{App.i18n.translateInline('escalated')}"
    App.i18n.translateInline(type.displayName())

  iconTextClass: ->
    "task-state-#{ @getState() }-color"

  iconActivity: (user) ->
    return if !user
    if @owner_id == user.id
      return 'important'
    ''
  searchResultAttributes: ->
    display:    "##{@number} - #{@title}"
    id:         @id
    class:      "task-state-#{ @getState() } ticket-popover"
    url:        @uiUrl()
    icon:       'task-state'
    iconClass:  @getState()

  activityMessage: (item) ->
    return if !item
    if item.type is 'create'
      return App.i18n.translateContent('%s created Ticket |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated Ticket |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'reminder_reached'
      return App.i18n.translateContent('Pending reminder reached for Ticket |%s|', item.title)
    else if item.type is 'escalation'
      return App.i18n.translateContent('Ticket |%s| is escalated!', item.title)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."
