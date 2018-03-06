class App.ReportProfile extends App.Model
  @configure 'ReportProfile', 'name', 'condition', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/report_profiles'
  @configure_attributes = [
    { name: 'name',       display: 'Name',      tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'condition',  display: 'Filter',    tag: 'ticket_selector', null: true },
    { name: 'updated_at', display: 'Updated',   tag: 'datetime',  readonly: 1 },
    { name: 'active',     display: 'Active',    tag: 'active',    default: true },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
  ]
