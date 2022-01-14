class App.TicketPriority extends App.Model
  @configure 'TicketPriority', 'name', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_priorities'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),    tag: 'input',     type: 'text', limit: 100, null: false, translate: true },
    { name: 'active',     display: __('Active'),  tag: 'active',    default: true },
    { name: 'updated_at', display: __('Updated'), tag: 'datetime',  readonly: 1 },
    { name: 'created_at', display: __('Created'), tag: 'datetime',  readonly: 1 },
  ]
  @configure_translate = true
  @configure_overview = [
    'name',
  ]
