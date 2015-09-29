class App.Network extends App.Model
  @configure 'Network', 'name', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @configure_attributes = [
    { name: 'name',       display: 'Name',    tag: 'input', type: 'text', limit: 100, null: false },
    { name: 'note',       display: 'Note',    note: 'Notes are visible to agents only, never to customers.', tag: 'textarea', limit: 250, null: true },
    { name: 'updated_at', display: 'Updated', tag: 'datetime', readonly: 1 },
    { name: 'active',     display: 'Active',  tag: 'active', default: true },
  ]
