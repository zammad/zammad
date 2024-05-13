class App.Permission extends App.Model
  @configure 'Permission', 'name', 'description', 'active', 'preferences'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/permissions'
