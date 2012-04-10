class App.HistoryObject extends App.Model
  @configure 'HistoryObject', 'name'
  @extend Spine.Model.Ajax
  @url: '/history_objects'
