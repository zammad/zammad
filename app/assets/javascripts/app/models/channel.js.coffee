class App.Channel extends App.Model
  @configure 'Channel', 'adapter', 'area', 'options', 'group_id', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @api_path + '/channels'
