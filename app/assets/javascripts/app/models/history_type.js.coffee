class App.HistoryType extends App.Model
  @configure 'HistoryType', 'name'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/history_types'
