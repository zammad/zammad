class App.Signature extends App.Model
  @configure 'Signature', 'name', 'body', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @api_path + '/signatures'

  @configure_attributes = [
    { name: 'name',                 display: 'Name',              tag: 'input',    type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'body',                 display: 'Text',              tag: 'textarea',               limit: 250, 'null': true, 'class': 'span4', rows: 10 },
    { name: 'note',                 display: 'Note',              tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true, 'class': 'span4' },
    { name: 'updated_at',           display: 'Updated',           type: 'time',    readonly: 1 },
    { name: 'active',               display: 'Active',            tag: 'boolean',  type: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_overview = [
    'name',
  ]
