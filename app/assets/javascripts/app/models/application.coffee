class App.Application extends App.Model
  @configure 'Application', 'name', 'redirect_uri', 'uid', 'secret'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/applications'

  @configure_attributes = [
    { name: 'name',             display: 'Name',         tag: 'input', type: 'text',  limit: 100, null: false },
    { name: 'redirect_uri',     display: 'Redirect URI', tag: 'textarea',             limit: 250, null: false, note: 'Use one line per URI' },
    { name: 'uid',              display: 'Application ID', tag: 'input', type: 'text', null: true, readonly: 1 },
    { name: 'secret',           display: 'Application secret', tag: 'input', type: 'text', null: true },
    { name: 'created_at',       display: 'Created',      tag: 'datetime', readonly: 1 },
    { name: 'updated_at',       display: 'Updated',      tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = [
    'name', 'uid'
  ]
  @configure_delete = true
