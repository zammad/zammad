class KnowledgeBase extends App.KbPopoverProvider
  @klass = App.KnowledgeBaseTranslation
  @selectorCssClassPrefix = 'kb'

App.PopoverProvider.registerProvider('KnowledgeBase', KnowledgeBase)
