class App.Job extends App.Model
  @configure 'Job', 'name', 'timeplan', 'condition', 'perform', 'disable_notification', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/jobs'
  @configure_attributes = [
    { name: 'name',                 display: __('Name'),                            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'timeplan',             display: __('When should the job run?'),        tag: 'timer', null: true },
    { name: 'condition',            display: __('Conditions for affected objects'), tag: 'ticket_selector', null: true, executionTime: true, noCurrentUser: true },
    { name: 'perform',              display: __('Execute changes on objects'),      tag: 'ticket_perform_action', null: true, notification: true, ticket_delete: true },
    { name: 'disable_notification', display: __('Disable Notifications'),           tag: 'boolean', default: true },
    { name: 'note',                 display: __('Note'),                            tag: 'textarea', note: __('Notes are visible to agents only, never to customers.'), limit: 250, null: true },
    { name: 'active',               display: __('Active'),                          tag: 'active', default: true },
    { name: 'matching',             display: __('Will process'),                    readonly: 1 },
    { name: 'processed',            display: __('Has processed'),                   readonly: 1 },
    { name: 'last_run_at',          display: __('Last run'),                        tag: 'datetime', readonly: 1, include_timezone: true },
    { name: 'next_run_at',          display: __('Scheduled for'),                   tag: 'datetime', readonly: 1, include_timezone: true },
    { name: 'running',              display: __('Running'),                         tag: 'boolean', readonly: 1 },
    { name: 'created_by_id',        display: __('Created by'),                      relation: 'User', readonly: 1 },
    { name: 'created_at',           display: __('Created'),                         tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',        display: __('Updated by'),                      relation: 'User', readonly: 1 },
    { name: 'updated_at',           display: __('Updated'),                         tag: 'datetime', readonly: 1 },
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
