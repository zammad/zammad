class App.ReportProfile extends App.Model
  @configure 'ReportProfile', 'name', 'condition', 'role_ids', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/report_profiles'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),      tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'condition',  display: __('Filter'),    tag: 'ticket_selector', null: true },
    { name: 'role_ids',   display: __('Available for the following roles'), tag: 'column_select', multiple: true, null: true, relation: 'Role', translate: true },
    { name: 'updated_at', display: __('Updated'),   tag: 'datetime',  readonly: 1 },
    { name: 'active',     display: __('Active'),    tag: 'active',    default: true },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
  ]
