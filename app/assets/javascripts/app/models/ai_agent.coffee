class App.AIAgent extends App.Model
  @configure 'AIAgent', 'name', 'agent_type', 'type_enrichment_data', 'definition', 'action_definition', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ai_agents'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),               tag: 'input',    type: 'text', limit: 250, null: false },
    { name: 'agent_type', display: __('Type'),               tag: 'select',   relation: 'AIAgentType', null: false, nulloption: true },
    { name: 'triggers',   display: __('Used in triggers'),                    readonly: 1 },
    { name: 'jobs',       display: __('Used in schedulers'),                  readonly: 1 },
    { name: 'note',       display: __('Note'),               tag: 'richtext', null: true, note: '', limit: 250 },
    { name: 'active',     display: __('Active'),             tag: 'active',   default: true },
    { name: 'updated_at', display: __('Updated'),            tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'agent_type',
    'triggers',
    'jobs',
    'note',
  ]

  @description = __('''
AI agents enable streamlined processing powered by artificial intelligence. You can execute AI agents via triggers or schedulers.
''')

  @badges = [
    {
      display: __('Unused'),
      title: __('For this agent to run, it needs to be used in a trigger or scheduler.'),
      active: (object) ->
        _.isEmpty(object.references) and object.active
      attribute: 'name'
      class: 'warning'
    }
  ]
