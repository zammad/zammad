class App.EmailAddress extends App.Model
  @configure 'EmailAddress', 'realname', 'email', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/email_addresses'

  @configure_attributes = [
    { name: 'realname',   display: 'Realname',  tag: 'input', type: 'text', limit: 250, null: false },
    { name: 'email',      display: 'Email',     tag: 'input', type: 'text', limit: 250, null: false },
    { name: 'note',       display: 'Note',      tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true },
    { name: 'updated_at', display: 'Updated',   tag: 'datetime', readonly: 1 },
    { name: 'active',     display: 'Active',    tag: 'boolean', type: 'boolean', default: true, null: false },
  ]
  @configure_overview = [
    'realname', 'email'
  ]
