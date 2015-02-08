class App.Job extends App.Model
  @configure 'Job', 'name', 'timeplan', 'condition', 'execute', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/jobs'
  @configure_attributes = [
    { name: 'name',           display: 'Name',        tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'timeplan',       display: 'The times where the job should run.', tag: 'timeplan', null: true },
    { name: 'condition',      display: 'Conditions for matching objects.', tag: 'ticket_attribute_selection', null: true },
    { name: 'execute',        display: 'Execute changes on objects.', tag: 'ticket_attribute_set', null: true },
    { name: 'note',           display: 'Note',        tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true },
    { name: 'active',         display: 'Active',      tag: 'active', default: true },
    { name: 'matching',       display: 'Matching',    readonly: 1 },
    { name: 'processed',      display: 'Processed',   readonly: 1 },
    { name: 'last_run_at',    display: 'Last run',    tag: 'datetime', readonly: 1 },
    { name: 'running',        display: 'Running',     tag: 'boolean', readonly: 1 },
    { name: 'created_by_id',  display: 'Created by',  relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',     tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',  relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',     tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
    'last_run_at',
    'matching',
    'processed',
  ]
