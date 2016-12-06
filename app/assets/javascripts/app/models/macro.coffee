class App.Macro extends App.Model
  @configure 'Macro', 'name', 'perform', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/macros'
  @configure_attributes = [
    { name: 'name',       display: 'Name',          tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'perform',    display: 'Execute changes on objects.', tag: 'ticket_perform_action', null: true },
    { name: 'updated_at', display: 'Updated',       tag: 'datetime',  readonly: 1 },
    { name: 'note',       display: 'Note',          tag: 'textarea',  limit: 250, null: true },
    { name: 'active',     display: 'Active',        tag: 'active',    default: true },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]

  @description = '''
Macros are....

'''