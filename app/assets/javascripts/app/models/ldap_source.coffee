class App.LdapSource extends App.Model
  @configure 'LdapSource', 'name', 'preferences', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ldap_sources'
  @configure_attributes = [
    { name: 'name',           display: __('Name'), tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'active',         display: __('Active'), tag: 'active', default: true },
    { name: 'created_by_id',  display: __('Created by'), relation: 'User', readonly: 1 },
    { name: 'created_at',     display: __('Created'), tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: __('Updated by'), relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: __('Updated'), tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]
