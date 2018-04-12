class App.Signature extends App.Model
  @configure 'Signature', 'name', 'body', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/signatures'

  @configure_attributes = [
    { name: 'name',           display: 'Name',          tag: 'input',    type: 'text', limit: 100, 'null': false },
    { name: 'body',           display: 'Text',          tag: 'richtext',               limit: 500, 'null': true, plugins: [
      {
        controller: 'WidgetPlaceholder'
        params:
          objects: [
            {
              prefix: 'ticket'
              object: 'Ticket'
              display: 'Ticket'
            },
            {
              prefix: 'user'
              object: 'User'
              display: 'Current User'
            },
          ]
      },
    ]},
    { name: 'note',           display: 'Note',          tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true },
    { name: 'active',         display: 'Active',        tag: 'active',    default: true },
    { name: 'created_by_id',  display: 'Created by',    relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',       tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',    relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',       tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = [
    'name',
  ]
  @configure_clone = true
