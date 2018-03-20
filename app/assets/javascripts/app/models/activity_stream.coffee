class App.ActivityStream extends App.Model
  @configure 'ActivityStream', 'name'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/activity_steams'
