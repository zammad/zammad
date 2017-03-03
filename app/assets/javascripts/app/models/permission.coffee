class App.Permission extends App.Model
  @configure 'Permission', 'name', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/permissions'
