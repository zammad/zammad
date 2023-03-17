class KnowledgeBaseCategory extends App.KbPopoverProvider
  @klass = App.KnowledgeBaseCategoryTranslation
  @selectorCssClassPrefix = 'kb-category'

App.PopoverProvider.registerProvider('KnowledgeBaseCategory', KnowledgeBaseCategory)
