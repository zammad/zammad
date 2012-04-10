class App.HistoryAttribute extends App.Model
  @configure 'HistoryAttribute', 'name'
  @extend Spine.Model.Ajax
  @url: '/history_attributes'
