class App.Translation extends App.Model
  @configure 'Translation', 'source', 'target', 'locale'
  @extend Spine.Model.Ajax
  @url: @api_path + '/translations'