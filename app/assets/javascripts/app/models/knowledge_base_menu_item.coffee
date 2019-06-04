class App.KnowledgeBaseMenuItem extends App.Model
  @configure 'KnowledgeBaseMenuItem', 'kb_locale_id', 'position', 'title', 'url'

  @using_kb_locale: (kb_locale) ->
    items = @findAllByAttribute('kb_locale_id', kb_locale.id)
    items.sort( (a, b) -> if a.position < b.position then -1 else 1)
    items
