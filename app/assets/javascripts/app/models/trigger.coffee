class App.Trigger extends App.Model
  @configure 'Trigger', 'name', 'activator', 'execution_condition_mode', 'condition', 'perform', 'active', 'note', 'localization', 'timezone'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/triggers'
  @configure_attributes = [
    { name: 'name',                     display: __('Name'),             tag: 'input',     type: 'text', limit: 100,  null: false },
    { name: 'activator',                display: __('Activated by'),     tag: 'select',    type: 'text', limit: 50,   null: true, options: { action: __('Action'), time: __('Time event') }, note: __('Triggers activated by actions are executed whenever a ticket is created or updated, while triggers activated by time events are executed when certain times are reached (e.g. pending time, escalation).'), translate: true },
    { name: 'execution_condition_mode', display: __('Action execution'), tag: 'radio',     type: 'text', limit: 50,   null: true, options: [ { value: 'selective', name: __('Selective (default)'), note: __('When at least one field from conditions was updated or article was added and conditions match') }, { value: 'always', name: __('Always'), note: __('When conditions match') } ] },
    { name: 'condition',                display: __('Conditions for affected objects'), tag: 'ticket_selector',       null: false, preview: false, action: true, hasChanged: true, executionTime: true, hasReached: true, hasRegexOperators: true },
    { name: 'perform',                  display: __('Execute changes on objects'),      tag: 'ticket_perform_action', null: true, notification: true, trigger: true, subscribe: true },
    { name: 'execution_localization',   display: __('Localization of execution changes'), tag: 'switch', null: true, label_class: 'hidden', help: __('Customize the default locale and timezone during replacement of template variables.') },
    { name: 'localization',             display: __('Locale'),   tag: 'language',  null: true, class: 'input', show_system_default_option: true, item_class: 'collapse formGroup--halfSize' },
    { name: 'timezone',                 display: __('Timezone'), tag: 'timezone',  null: true, class: 'input', show_system_default_option: true, item_class: 'collapse formGroup--halfSize' },
    { name: 'note',                     display: __('Note'),             tag: 'textarea',                limit: 250,  null: true },
    { name: 'active',                   display: __('Active'),           tag: 'active',    default: true },
    { name: 'updated_at',               display: __('Updated'),          tag: 'datetime',  readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
  ]

  @description = __('''
Every time a customer creates a new ticket, they automatically receive a confirmation email to assure them that their issue has been submitted successfully. This behavior is built into Zammad, but it’s also highly customizable, and you can set up other automated actions just like it.

Maybe you want to set a higher priority on any ticket with the word “urgent” in the title. Maybe you want to avoid sending auto-reply emails to customers from certain organizations. Maybe you want mark a ticket as “pending” whenever someone adds an internal note to a ticket.

Whatever it is, you can do it with triggers: actions that watch tickets for certain changes, and then fire off whenever those changes occur.
''')
