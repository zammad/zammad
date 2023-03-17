class App.KnowledgeBaseAnswerTranslationState extends App.Model
  @configure 'KnowledgeBaseAnswerTranslationState', 'name'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/knowledge_base/answer/translation/states'
