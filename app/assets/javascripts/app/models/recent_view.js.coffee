class App.RecentView extends App.Model
  @configure 'RecentView', 'name'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/recent_view'
