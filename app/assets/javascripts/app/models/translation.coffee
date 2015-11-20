class App.Translation extends App.Model
  @configure 'Translation', 'source', 'target', 'target_initial', 'locale'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/translations'