class App.KnowledgeBaseTranslation extends App.Model
  @configure 'KnowledgeBaseTranslation', 'title', 'footer_note'
  @extend Spine.Model.Ajax
  @extend App.KnowledgeBaseTranslationable
  @url: @apiPath + '/knowledge_base/translations'
  @configure_attributes = [
      { name: 'title', display: 'Title', tag: 'input' },
    ]

  parent: ->
    App.KnowledgeBase.find(@knowledge_base_id)
