class App.TicketState extends App.Model
  @configure 'TicketState', 'name', 'state_type_id', 'next_state_id', 'default_create', 'default_follow_up', 'ignore_escalation', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_states'
  @configure_attributes = [
    { name: 'name',                 display: __('Name'),                tag: 'input',     type: 'text', limit: 100, null: false, translate: true },
    { name: 'state_type_id',        display: __('Type'),                tag: 'select',    null: false, relation: 'TicketStateType', nulloption: true, help: __('Zammad uses state types to know what it should do with your state. This allows you to have different types like pending actions, pending reminders or closed states. Take a look at our system object documentation for more information.'), helpLink: ' <a href="https://admin-docs.zammad.org/en/latest/system/objects.html#state-type-reference" target="_blank">🔗</a>', translate: true },
    { name: 'next_state_id',        display: __('Next State'),          tag: 'select',    null: true, relation: 'TicketState', nulloption: true },
    { name: 'ignore_escalation',    display: __('Ignore Escalation'),   tag: 'boolean',   null: false, default: false },
    { name: 'note',                 display: __('Note'),                tag: 'textarea',  limit: 250, null: true },
    { name: 'active',               display: __('Active'),              tag: 'active',    default: true },
    { name: 'updated_at',           display: __('Updated'),             tag: 'datetime',  readonly: 1 },
    { name: 'created_at',           display: __('Created'),             tag: 'datetime',  readonly: 1 },
  ]
  @configure_clone = true
  @configure_translate = true
  @configure_overview = [
    'name',
    'state_type_id',
  ]

  @description = __('''
A ticket's state is used to categorize and manage the lifecycle of a ticket or customer inquiry.
''')

  @badges = [
    {
      display: __('Default for new tickets')
      active: (object) ->
        object.default_create
      attribute: 'name'
      class: 'primary'
    },
    {
      display: __('Default for follow-ups')
      active: (object) ->
        object.default_follow_up
      attribute: 'name'
      class: 'primary'
    }
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
        # Legacy systems may have a state type 'removed', which should still be available.
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
