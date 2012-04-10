class App.Post extends App.Model
  @configure 'Post', 'title', 'content'
  @extend Spine.Model.Ajax