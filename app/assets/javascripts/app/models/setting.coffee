class App.Setting extends App.Model
  @configure 'Setting', 'name', 'state_current'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/settings'
