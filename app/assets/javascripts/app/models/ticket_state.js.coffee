class App.TicketState extends App.Model
  @configure 'TicketState', 'name', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_states'
  @configure_attributes = [
    { name: 'name',       display: 'Name',    tag: 'input',   type: 'text', limit: 100, 'null': false, translate: true },
    { name: 'active',     display: 'Active',  tag: 'boolean', type: 'boolean', 'default': true, 'null': false },
    { name: 'updated_at', display: 'Updated', type: 'time',   readonly: 1 },
    { name: 'created_at', display: 'Created', type: 'time',   readonly: 1 },
  ]
  @configure_translate = true
  @configure_overview = [
    'name',
  ]