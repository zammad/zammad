class App.Permission extends App.Model
  @configure 'Role', 'name', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/permissions'
