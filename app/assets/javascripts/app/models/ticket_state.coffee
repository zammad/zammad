class App.TicketState extends App.Model
  @configure 'TicketState', 'name', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_states'
  @configure_attributes = [
    { name: 'name',       display: 'Name',    tag: 'input',     type: 'text', limit: 100, null: false, translate: true },
    { name: 'active',     display: 'Active',  tag: 'active',    default: true },
    { name: 'updated_at', display: 'Updated', tag: 'datetime',  readonly: 1 },
    { name: 'created_at', display: 'Created', tag: 'datetime',  readonly: 1 },
  ]
  @configure_translate = true
  @configure_overview = [
    'name',
  ]

  @byCategory: (category) ->
    switch category
      when 'open'
        state_types = ['new', 'open', 'pending reminder', 'pending action']
        break
      when 'pending_reminder'
        state_types = ['pending reminder']
        break
      when 'pending_action'
        state_types = ['pending action']
        break
      when 'pending'
        state_types = ['pending reminder', 'pending action']
        break
      when 'work_on'
        state_types = ['new', 'open']
        break
      when 'work_on_all'
        state_types = ['new', 'open', 'pending reminder']
        break
      when 'viewable'
        state_types = ['new', 'open', 'pending reminder', 'pending action', 'closed', 'removed']
        break
      when 'viewable_agent_new'
        state_types = ['new', 'open', 'pending reminder', 'pending action', 'closed']
        break
      when 'viewable_agent_edit'
        state_types = ['open', 'pending reminder', 'pending action', 'closed']
        break
      when 'viewable_customer_new'
        state_types = ['new', 'closed']
        break
      when 'viewable_customer_edit'
        state_types = ['open', 'closed']
        break
      when 'closed'
        state_types = ['closed']
        break
      when 'merged'
        state_types = ['merged']
        break
      else
        state_types = []

    result = []
    for state in App.TicketState.all()
      continue if !_.contains(state_types, App.TicketStateType.find(state.state_type_id).name)
      result.push(state)
    result
