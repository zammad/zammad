class App.KnowledgeBaseSidebarTags extends App.Controller
  className: 'sidebar-block'

  constructor: ->
    super

    @widget = new App.WidgetTag(
      el:          @el
      templateName: 'knowledge_base/sidebar/tags'
      object_type: 'KnowledgeBaseAnswer'
      object:      @object
      tags:        @object.tags
    )

  updateIfNeeded: ->
    @widget.reload(@object.tags)
