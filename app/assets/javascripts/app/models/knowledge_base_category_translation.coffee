class App.KnowledgeBaseCategoryTranslation extends App.Model
  @configure 'KnowledgeBaseCategoryTranslation', 'title', 'locale_id', 'category_id'
  @extend Spine.Model.Ajax
  @extend App.KnowledgeBaseTranslationable
  @url: @apiPath + '/knowledge_base/category/translations'

  parent: ->
    App.KnowledgeBaseCategory.find(@category_id)
