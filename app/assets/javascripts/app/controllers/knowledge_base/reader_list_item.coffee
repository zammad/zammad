class App.KnowledgeBaseReaderListItem extends App.Controller
  constructor: ->
    super
    @render()
    @el[0].dataset.id = @item.id

    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', =>
      @render()

  tag:       'li'
  className: 'section'

  render: ->
    if @sort_order != null && @sort_order != @item.position
      App.Delay.set(=>
        @parentController.parentRefreshed()
      , 1000, 'kb_reader_list_resort')

    @sort_order = @item.position

    attrs = @item.attributesForRendering(@kb_locale, isEditor: @isEditor)

    @el
      .prop('className')
      .split(' ')
      .filter  (elem) -> elem.match 'kb-item--'
      .forEach (elem) -> @el.removeClass(elem)

    @el.addClass attrs.className

    @html App.view('knowledge_base/_reader_list_item')(
      item:    attrs
      iconset: @iconset
    )
