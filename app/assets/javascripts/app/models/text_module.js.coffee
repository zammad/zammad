class App.TextModule extends App.Model
  @configure 'TextModule', 'name', 'keywords', 'content', 'active', 'group_ids', 'user_id', 'updated_at'
  @extend Spine.Model.Ajax
  @url: 'api/text_modules'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',     type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'keywords',   display: 'Keywords',            tag: 'input',     type: 'text', limit: 100, 'null': true,  'class': 'span4' },
    { name: 'content',    display: 'Content',             tag: 'textarea',                limit: 250, 'null': false, 'class': 'span4' },
    { name: 'updated_at', display: 'Updated',             type: 'time', readonly: 1 },
    { name: 'active',     display: 'Active',              tag: 'boolean',   note: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
    'keywords',
    'content',
  ]
