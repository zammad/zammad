class App.HistoryType extends App.Model
  @configure 'HistoryType', 'name'
  @extend Spine.Model.Ajax
  @url: @api_path + '/history_types'
