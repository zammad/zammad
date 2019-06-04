class App.KnowledgeBaseSidebarCategories extends App.KnowledgeBaseSidebarGenericList
  templateName: 'categories'
  title:        'Categories'
  emptyNote:    'No categories'

  constructor: ->
    super

  templateOptions: ->
    attrs = super
    attrs.isRoot = @object instanceof App.KnowledgeBase
    attrs

  urlNew: ->
    prefix = "#knowledge_base/#{@object.knowledge_base().id}/category/"

    if @object instanceof App.KnowledgeBaseCategory
      prefix + "#{@object.id}/new"
    else if @object instanceof App.KnowledgeBase
      prefix + 'category/new'

  categories: ->
    if @object instanceof App.KnowledgeBaseCategory
      @object.children()
    else if @object instanceof App.KnowledgeBase
      @object.rootCategories()
    else
      []

  items: ->
    @categories()
      .sort (a, b) ->
        a.position - b.position
      .map (elem) =>
        elem.attributesForRendering(@kb_locale, action: 'edit', isEditor: true)

  reorderSaveUrl: ->
    if @object instanceof App.KnowledgeBaseCategory
      @object.generateURL('reorder_categories')
    else
      @object.url() + '/categories/reorder_root_categories'

  newObject: ->
    parent = if @object instanceof App.KnowledgeBaseCategory then @object
    new App.KnowledgeBaseCategory(parent_id: parent?.id, knowledge_base_id: @object.knowledge_base().id)
