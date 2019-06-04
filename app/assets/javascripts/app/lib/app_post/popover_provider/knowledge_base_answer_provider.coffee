class KnowledgeBaseAnswer extends App.KbPopoverProvider
  @klass = App.KnowledgeBaseAnswerTranslation
  @selectorCssClassPrefix = 'kb-answer'

App.PopoverProvider.registerProvider('KnowledgeBaseAnswer', KnowledgeBaseAnswer)
