class App.Setting extends App.Model
  @configure 'Setting', 'name', 'state'
  @extend Spine.Model.Ajax
  @url: @api_path + '/settings'
