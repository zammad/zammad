class App.Trigger extends App.Model
  @configure 'Trigger', 'name', 'condition', 'perform', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/triggers'
  @configure_attributes = [
    { name: 'name',       display: 'Name',          tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'condition',  display: 'Conditions for effected objects', tag: 'ticket_selector', null: false, preview: false, action: true, hasChanged: true, executionTime: true },
    { name: 'perform',    display: 'Execute changes on objects',      tag: 'ticket_perform_action', null: true, notification: true, trigger: true },
    { name: 'active',     display: 'Active',        tag: 'active',    default: true },
    { name: 'updated_at', display: 'Updated',       tag: 'datetime',  readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
  ]

  @description = '''
Every time a customer creates a new ticket, they automatically receive a confirmation email to assure them that their issue has been submitted successfully. This behavior is built into Zammad, but it’s also highly customizable, and you can set up other automated actions just like it.

Maybe you want to set a higher priority on any ticket with the word “urgent” in the title. Maybe you want to avoid sending auto-reply emails to customers from certain organizations. Maybe you want mark a ticket as “pending” whenever someone adds an internal note to a ticket.

Whatever it is, you can do it with triggers: actions that watch tickets for certain changes, and then fire off whenever those changes occur.
'''

