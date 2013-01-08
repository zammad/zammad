class App.Role extends App.Model
  @configure 'Role', 'name', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: 'api/roles'
  @configure_attributes = [
    { name: 'name',       display: 'Name',    tag: 'input',   type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'note',       display: 'Note',    tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true, 'class': 'span4' },
    { name: 'updated_at', display: 'Updated', type: 'time',   readonly: 1 },
    { name: 'active',     display: 'Active',  tag: 'boolean', type: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_overview = [
    'name',
  ]
