class App.Channel extends App.Model
  @configure 'Channel', 'adapter', 'area', 'options', 'group_id', 'active'
  @extend Spine.Model.Ajax
  @url: '/api/channels'
