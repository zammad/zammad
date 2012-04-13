class App.Channel extends App.Model
  @configure 'Channel', 'adapter', 'area', 'options', 'group_id', 'active'
  @extend Spine.Model.Ajax
  
  @configure_attributes = [
    { name: 'adapter',  display: 'Adapter',  tag: 'input',   type: 'text', limit: 100, null: false, 'class': 'xlarge' },
    { name: 'area',     display: 'Area',     tag: 'input',   type: 'text', limit: 100, null: false, 'class': 'xlarge' },
#    { name: 'host',     display: 'Host',     tag: 'input',   type: 'text', limit: 100, null: false, 'class': 'xlarge' },
#    { name: 'user',     display: 'User',     tag: 'input',   type: 'text', limit: 100, null: false, 'class': 'xlarge' },
#    { name: 'password', display: 'Password', tag: 'input',   type: 'text', limit: 100, null: fa, 'class': 'xlarge' },
    { name: 'options',  display: 'Area',     tag: 'input',   type: 'text', limit: 100, null: false, 'class': 'xlarge' },
    { name: 'group_id', display: 'Group',    tag: 'option',  type: 'text', limit: 100, null: true, 'class': 'xlarge' },
    { name: 'active',   display: 'Active',   tag: 'boolean', type: 'boolean', 'default': true, null: true, 'class': 'xlarge' },
  ]