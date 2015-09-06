class App.StatsStore extends App.Model
  @configure 'StatsStore', 'name', 'state'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/stats_store'
