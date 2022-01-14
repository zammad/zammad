class App.Application extends App.Model
  @configure 'Application', 'name', 'redirect_uri'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/applications'

  @configure_attributes = [
    { name: 'name',             display: __('Name'),         tag: 'input', type: 'text',  limit: 100, null: false },
    { name: 'redirect_uri',     display: __('Callback URL'), tag: 'textarea',             limit: 250, null: false, note: __('Use one line per URI') },
    { name: 'clients',          display: __('Clients'),      tag: 'input', readonly: 1 },
    { name: 'created_at',       display: __('Created'),      tag: 'datetime', readonly: 1 },
    { name: 'updated_at',       display: __('Updated'),      tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = [
    'name', 'redirect_uri', 'clients'
  ]
  @configure_delete = true
