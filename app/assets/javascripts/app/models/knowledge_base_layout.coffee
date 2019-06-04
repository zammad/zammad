class App.KnowledgeBaseLayout extends App.Model
  @configure 'KnowledgeBaseLayout', 'name'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/knowledge_base/layouts'
