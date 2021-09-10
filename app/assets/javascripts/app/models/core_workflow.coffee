class App.CoreWorkflow extends App.Model
  @configure 'CoreWorkflow', 'name', 'object', 'preferences', 'condition_saved', 'condition_selected', 'perform', 'priority', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/core_workflows'
  @configure_attributes = [
    { name: 'name', display: 'Name', tag: 'input', type: 'text', limit: 100, null: false },
    { name: 'object', display: 'Object', tag: 'select', null: false, nulloption: true },
    { name: 'preferences::screen', display: 'Context', tag: 'select', translate: true, null: true, multiple: true, nulloption: true },
    { name: 'condition_selected', display: 'Selected conditions', tag: 'core_workflow_condition', null: true, preview: false },
    { name: 'condition_saved', display: 'Saved conditions', tag: 'core_workflow_condition', null: true, preview: false },
    { name: 'perform', display: 'Action', tag: 'core_workflow_perform', null: true, preview: false },
    { name: 'stop_after_match', display: 'Stop after match', tag: 'boolean', null: false, default: false },
    { name: 'priority', display: 'Priority', tag: 'integer', type: 'text', limit: 100, null: false, default: 500 },
    { name: 'active', display: 'Active', tag: 'active', default: true },
    { name: 'updated_at', display: 'Updated', tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'priority',
  ]

  @description = '''
Core Workflows are actions or constraints on selections in forms. Depending on an action, it is possible to hide or restrict fields or to change the obligation to fill them in.
'''

