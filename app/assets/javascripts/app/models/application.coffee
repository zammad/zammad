class App.Application extends App.Model
  @configure 'Application', 'name', 'redirect_uri'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/applications'

  @configure_attributes = [
    { name: 'name',             display: 'Name',         tag: 'input', type: 'text',  limit: 100, null: false },
    { name: 'redirect_uri',     display: 'Callback URL', tag: 'textarea',             limit: 250, null: false, note: 'Use one line per URI' },
    { name: 'clients',          display: 'Clients',      tag: 'input', readonly: 1 },
    { name: 'created_at',       display: 'Created',      tag: 'datetime', readonly: 1 },
    { name: 'updated_at',       display: 'Updated',      tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = [
    'name', 'redirect_uri', 'clients'
  ]
  @configure_delete = true
