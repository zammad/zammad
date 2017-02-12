class App.TicketPriority extends App.Model
  @configure 'TicketPriority', 'name', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_priorities'
  @configure_attributes = [
    { name: 'name',       display: 'Name',    tag: 'input',     type: 'text', limit: 100, null: false, translate: true },
    { name: 'active',     display: 'Active',  tag: 'active',    default: true },
    { name: 'updated_at', display: 'Updated', tag: 'datetime',  readonly: 1 },
    { name: 'created_at', display: 'Created', tag: 'datetime',  readonly: 1 },
  ]
  @configure_translate = true
  @configure_overview = [
    'name',
  ]
