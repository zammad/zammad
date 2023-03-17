class App.KnowledgeBaseSidebarActions extends App.Controller
  className: 'sidebar-block'

  constructor: ->
    super

    actions = @object?.contentSidebarActions(@kb_locale)

    html = if actions
             App.view('knowledge_base/sidebar/actions')(actions: actions)
           else
             ''

    @html html
