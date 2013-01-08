class App.EmailAddress extends App.Model
  @configure 'EmailAddress', 'realname', 'email', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: 'api/email_addresses'

  @configure_attributes = [
    { name: 'realname',             display: 'Realname',          tag: 'input', type: 'text', limit: 250, 'null': false, 'class': 'span4' },
    { name: 'email',                display: 'Email',             tag: 'input', type: 'text', limit: 250, 'null': false, 'class': 'span4' },
    { name: 'note',                 display: 'Note',              tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true, 'class': 'span4' },
    { name: 'updated_at',           display: 'Updated',           type: 'time', readonly: 1 },
    { name: 'active',               display: 'Active',            tag: 'boolean', type: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_overview = [
    'realname', 'email'
  ]
