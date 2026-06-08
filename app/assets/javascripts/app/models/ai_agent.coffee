class App.AIAgent extends App.Model
  @configure 'AIAgent', 'name', 'agent_type', 'type_enrichment_data', 'definition', 'action_definition', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ai_agents'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),               tag: 'input',    type: 'text', limit: 250, null: false },
    { name: 'agent_type', display: __('Type'),               tag: 'select',   relation: 'AIAgentType', null: false, nulloption: true },
    { name: 'references', display: __('Used in'),                             readonly: 1 },
    { name: 'note',       display: __('Note'),               tag: 'richtext', null: true, note: '', limit: 250 },
    { name: 'active',     display: __('Active'),             tag: 'active',   default: true },
    { name: 'updated_at', display: __('Updated'),            tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'agent_type',
    'references',
    'note',
  ]

  @description = __('''
AI agents enable streamlined processing powered by artificial intelligence. You can execute AI agents via triggers or schedulers.
''')

  @badges = [
    {
      display: __('Unused'),
      active: (object) ->
        _.isEmpty(object.references) and object.active
      attribute: 'references'
      class: 'warning'
    }
  ]
