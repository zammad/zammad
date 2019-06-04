class App.KnowledgeBasePublicMenuForm extends App.Controller
  events:
    'show.bs.tab': 'willShow'

  willShow: ->
    @el.empty()

    for kb_locale in App.KnowledgeBase.find(@knowledge_base_id).kb_locales()
      menu_items = App.KnowledgeBaseMenuItem.using_kb_locale(kb_locale)

      form_item = new App.KnowledgeBasePublicMenuFormItem(
        knowledge_base_id: @knowledge_base_id,
        kb_locale: kb_locale,
        menu_items: menu_items
      )

      @el.append form_item.el
