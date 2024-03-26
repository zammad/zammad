class App.Job extends App.Model
  @configure 'Job', 'name', 'object', 'timeplan', 'condition', 'perform', 'disable_notification', 'note', 'active', 'localization', 'timezone'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/jobs'
  @configure_attributes = [
    { name: 'name',                 display: __('Name'),                            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'timeplan',             display: __('When should the job run?'),        tag: 'timer', null: true },
    { name: 'object',               display: __('Object'),                          tag: 'select', null: true, options: { Ticket: __('Ticket'), User: __('User'), Organization: __('Organization') }, default: 'Ticket', translate: true },
    { name: 'condition',            display: __('Conditions for affected objects'), tag: 'object_selector', null: true, executionTime: true, noCurrentUser: true },
    { name: 'perform',              display: __('Execute changes on objects'),      tag: 'object_perform_action', null: true, notification: true, ticket_delete: true, data_privacy_deletion_task: true },
    { name: 'disable_notification', display: __('Disable Notifications'),           tag: 'boolean', default: true },
    { name: 'execution_localization',   display: __('Localization of execution changes'), tag: 'switch', null: true, label_class: 'hidden', help: __('Customize the default locale and timezone during replacement of template variables.') },
    { name: 'localization',         display: __('Locale'),                          tag: 'language', null: true, class: 'input', show_system_default_option: true, item_class: 'collapse formGroup--halfSize' },
    { name: 'timezone',             display: __('Timezone'),                        tag: 'timezone', null: true, class: 'input', show_system_default_option: true, item_class: 'collapse formGroup--halfSize' },
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
    'object',
    'last_run_at',
    'processed',
    'next_run_at',
    'matching',
  ]
