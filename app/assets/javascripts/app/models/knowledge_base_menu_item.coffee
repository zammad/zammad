class App.KnowledgeBaseMenuItem extends App.Model
  @configure 'KnowledgeBaseMenuItem', 'kb_locale_id', 'position', 'title', 'url'

  @using_kb_locale: (kb_locale) ->
    items = @findAllByAttribute('kb_locale_id', kb_locale.id)
    items.sort( (a, b) -> if a.position < b.position then -1 else 1)
    items

  @using_kb_locale_location: (kb_locale, location) ->
    items = @all().filter (elem) -> elem.kb_locale_id is kb_locale.id and elem.location is location
    items.sort( (a, b) -> if a.position < b.position then -1 else 1)
    items
