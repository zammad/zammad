class App.TextModule extends App.Model
  @configure 'TextModule', 'name', 'keywords', 'content', 'active', 'group_ids', 'user_id', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/text_modules'
  @configure_attributes = [
    { name: 'name',       display: 'Name',          tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'keywords',   display: 'Keywords',      tag: 'input',     type: 'text', limit: 100, null: true },
    { name: 'content',    display: 'Content',       tag: 'textarea',                limit: 250, null: false },
    { name: 'updated_at', display: 'Updated',       tag: 'datetime',  readonly: 1 },
    { name: 'active',     display: 'Active',        tag: 'active',    default: true },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
    'keywords',
    'content',
  ]
