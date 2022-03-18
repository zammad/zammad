class App.Signature extends App.Model
  @configure 'Signature', 'name', 'body', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/signatures'

  @configure_attributes = [
    { name: 'name',           display: __('Name'),          tag: 'input',    type: 'text', limit: 100, 'null': false },
    { name: 'body',           display: __('Text'),          tag: 'richtext',               limit: 500, 'null': true, plugins: [
      {
        controller: 'WidgetPlaceholder'
        params:
          objects: [
            {
              prefix: 'ticket'
              object: 'Ticket'
              display: __('Ticket')
            },
            {
              prefix: 'user'
              object: 'User'
              display: __('Current User')
            },
          ]
      },
    ]},
    { name: 'note',           display: __('Note'),          tag: 'textarea', note: __('Notes are visible to agents only, never to customers.'), limit: 250, 'null': true },
    { name: 'active',         display: __('Active'),        tag: 'active',    default: true },
    { name: 'created_by_id',  display: __('Created by'),    relation: 'User', readonly: 1 },
    { name: 'created_at',     display: __('Created'),       tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: __('Updated by'),    relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: __('Updated'),       tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = [
    'name',
  ]
  @configure_clone = true
