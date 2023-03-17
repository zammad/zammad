class App.CoreWorkflow extends App.Model
  @configure 'CoreWorkflow', 'name', 'object', 'preferences', 'condition_saved', 'condition_selected', 'perform', 'stop_after_match', 'priority', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/core_workflows'
  @configure_attributes = [
    { name: 'name', display: __('Name'), tag: 'input', type: 'text', limit: 100, null: false },
    { name: 'object', display: __('Object'), tag: 'select', null: false, nulloption: true },
    { name: 'preferences::screen', display: __('Context'), tag: 'multiselect', translate: true, null: true, nulloption: true, multiple: true },
    { name: 'condition_selected', display: __('Selected conditions'), tag: 'core_workflow_condition', null: true, preview: false },
    { name: 'condition_saved', display: __('Saved conditions'), tag: 'core_workflow_condition', null: true, preview: false },
    { name: 'perform', display: __('Action'), tag: 'core_workflow_perform', null: true, preview: false },
    { name: 'stop_after_match', display: __('Stop after match'), tag: 'boolean', null: false, default: false },
    { name: 'priority', display: __('Priority'), tag: 'integer', type: 'text', limit: 100, null: false, default: 500 },
    { name: 'active', display: __('Active'), tag: 'active', default: true },
    { name: 'updated_at', display: __('Updated'), tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'priority',
  ]

  @description = __('Core Workflows are actions or constraints on selections in forms. Depending on an action, it is possible to hide or restrict fields or to change the obligation to fill them in.')
