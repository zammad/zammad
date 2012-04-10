class App.History extends App.Model
  @configure 'History', 'name'
  @extend Spine.Model.Ajax
  @url: '/histories'
