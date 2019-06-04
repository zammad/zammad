class App.KnowledgeBaseReaderListContainer extends App.Controller
  constructor: ->
    super
    @render()

    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', =>
      @parentRefreshed()

  tag:       'ul'
  className: 'sections'

  parentRefreshed: ->
    newIds = @children().map (elem) -> elem.id
    oldIds = @el.children().toArray().map (elem) -> parseInt(elem.dataset.id)

    if _.isEqual(newIds, oldIds)
      return

    App.Delay.set(=>
      @render()
    , 200, "#{@constructor.className}_#{@parent.constructor.className}:#{@parent.id}", 'kb_category_refresh')

  render: ->
    @el.empty()

    for child in @children()
      @el.append new App.KnowledgeBaseReaderListItem(
        item:             child
        isEditor:         @isEditor
        iconset:          @parent.knowledge_base().iconset
        kb_locale:        @kb_locale
        parentController: @
      ).el

class App.KnowledgeBaseReaderListContainer.Answers extends App.KnowledgeBaseReaderListContainer
  children: ->
    if !(@parent instanceof App.KnowledgeBaseCategory)
      return []

    answers = @parent.answers()

    if !@isEditor
      answers = answers.filter (elem) => elem.is_internally_published(@kb_locale)

    answers

class App.KnowledgeBaseReaderListContainer.Categories extends App.KnowledgeBaseReaderListContainer
  render: ->
    super

    @el.addClass "sections--#{@layout()}"
    @el[0].dataset['size'] = @size()

  children: ->
    # coffeelint: disable=indentation
    items = if @parent instanceof App.KnowledgeBase
              @parent.rootCategories()
            else if @parent instanceof App.KnowledgeBaseCategory
              @parent.children()
            else
              []
    # coffeelint: enable=indentation

    if !@isEditor
      items = items.filter (elem) => elem.visibleInternally(@kb_locale)

    items

  layout: ->
    if @parent instanceof App.KnowledgeBase
      @parent.knowledge_base().homepage_layout
    else
      @parent.knowledge_base().category_layout

  size: ->
    if @parent instanceof App.KnowledgeBase
      'large'
    else
      'medium'
