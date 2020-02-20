class App.Job extends App.Model
  @configure 'Job', 'name', 'timeplan', 'condition', 'perform', 'disable_notification', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/jobs'
  @configure_attributes = [
    { name: 'name',                 display: 'Name',                            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'timeplan',             display: 'When should the job run?',        tag: 'timer', null: true },
    { name: 'condition',            display: 'Conditions for effected objects', tag: 'ticket_selector', null: true, executionTime: true },
    { name: 'perform',              display: 'Execute changes on objects',      tag: 'ticket_perform_action', null: true, notification: true, ticket_delete: true },
    { name: 'disable_notification', display: 'Disable Notifications',           tag: 'boolean', default: true },
    { name: 'note',                 display: 'Note',                            tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true },
    { name: 'active',               display: 'Active',                          tag: 'active', default: true },
    { name: 'matching',             display: 'Will process',                    readonly: 1 },
    { name: 'processed',            display: 'Has processed',                   readonly: 1 },
    { name: 'last_run_at',          display: 'Last run',                        tag: 'datetime', readonly: 1 },
    { name: 'next_run_at',          display: 'Scheduled for',                   tag: 'datetime', readonly: 1 },
    { name: 'running',              display: 'Running',                         tag: 'boolean', readonly: 1 },
    { name: 'created_by_id',        display: 'Created by',                      relation: 'User', readonly: 1 },
    { name: 'created_at',           display: 'Created',                         tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',        display: 'Updated by',                      relation: 'User', readonly: 1 },
    { name: 'updated_at',           display: 'Updated',                         tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'last_run_at',
    'processed',
    'next_run_at',
    'matching',
  ]
