class App.Channel extends App.Model
  @configure 'Channel', 'adapter', 'area', 'options', 'group_id', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/channels'
  @configure_delete = true

  @configure_attributes = [
    { name: 'adapter',            display: 'Type',     tag: 'select',   multiple: false, null: false, options: { IMAP: 'IMAP', POP3: 'POP3' } },
    { name: 'options::host',      display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
    { name: 'options::user',      display: 'User',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
    { name: 'options::password',  display: 'Password', tag: 'input',    type: 'password', limit: 120, null: false, autocapitalize: false },
    { name: 'options::ssl',       display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' }, translate: true, default: true},
    { name: 'options::folder',    display: 'Folder',   tag: 'input',    type: 'text', limit: 120, null: true, autocapitalize: false },
    { name: 'group_id',           display: 'Group',    tag: 'select',   multiple: false, null: false, nulloption: true, relation: 'Group'  },
    { name: 'active',             display: 'Active',   tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' }, translate: true, default: true },
  ]
  @configure_overview = [
    'adapter', 'options::host', 'options::user', 'group'
  ]
