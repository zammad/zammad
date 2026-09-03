class App.KnowledgeBaseSidebarCategories extends App.KnowledgeBaseSidebarGenericList
  templateName: 'categories'
  title:        __('Categories')
  emptyNote:    __('No categories')

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

  # The same column name on a category and on the knowledge base: the top level lists categories
  #   only, so it carries the category mode alone.
  sortingMode: ->
    @object.category_sorting_mode

  # The list as it is stored - the records themselves, so the order can be read without the
  #   rendering stack behind #itemsForMode.
  categories: ->
    @categoriesForMode(@sortingMode())

  # Sorted here rather than through #children / #rootCategories, which only ever answer in the stored
  #   mode - the modal previews one that is not stored yet. The same ordering either way
  #   (App.KnowledgeBaseSorting is what those two call), so the block and the preview cannot
  #   disagree.
  categoriesForMode: (mode) ->
    App.KnowledgeBaseSorting.categories(@unsortedCategories(), mode, @kb_locale)

  # Re-sorted rather than mapped in order, because #attributesForRendering yields a flat hash with
  #   neither a position nor a timestamp left to sort by.
  itemsForMode: (mode) ->
    @categoriesForMode(mode)
      .map (elem) =>
        elem.attributesForRendering(@kb_locale, action: 'edit', isEditor: true)

  unsortedCategories: ->
    if @object instanceof App.KnowledgeBaseCategory
      @object.unsortedChildren()
    else if @object instanceof App.KnowledgeBase
      @object.unsortedRootCategories()
    else
      []

  reorderSaveUrl: ->
    if @object instanceof App.KnowledgeBaseCategory
      @object.generateURL('reorder_categories')
    else
      @object.url() + '/categories/reorder_root_categories'

  newObject: ->
    parent = if @object instanceof App.KnowledgeBaseCategory then @object
    new App.KnowledgeBaseCategory(parent_id: parent?.id, knowledge_base_id: @object.knowledge_base().id)
