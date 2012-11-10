class App.Overview extends Spine.Model
  @configure 'Overview', 'name', 'meta', 'condition', 'order', 'group_by', 'view', 'user_id', 'group_ids'
  @extend Spine.Model.Ajax
  @url: '/api/overviews'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',     type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'role_id',    display: 'Role',                tag: 'select',   multiple: false, nulloption: true, null: false, relation: 'Role', class: 'span4' },
    { name: 'user_id',    display: 'User',                tag: 'select',   multiple: false, nulloption: true, null: true,  relation: 'User', class: 'span4' },
#    { name: 'content',    display: 'Content',             tag: 'textarea',                limit: 250, 'null': false, 'class': 'span4' },
    { name: 'updated_at', display: 'Updated',             type: 'time', readonly: 1 },
    { name: 'active',     display: 'Active',              tag: 'boolean',   note: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_overview = [
    'name',
    'role',
    'active',
  ]