# The modal one list is ordered in: which mode it is listed in, and - while that mode arranges it by
#   hand - the order of the rows themselves.
#
# Generic on purpose: it knows about "modes", not about what is being ordered. The caller supplies
#   the modes, which one is stored, and the rows to show in each of them (see
#   App.KnowledgeBaseSidebarGenericList, its only caller today). Called without `modes` it is the
#   drag-only modal it has always been.
class App.ControllerReorderModal extends App.ControllerModal
  head: __('Change order')

  events:
    'click .js-sortingMode': 'selectMode'

  content: ->
    @view = $(App.view('reorder_modal')(
      modes: @modes
      mode:  @mode
    ))

    @renderTable()

    @view

  # Rebuilt from scratch on every mode change, because the rows themselves differ: each mode hands
  #   back the same records in its own order.
  #
  # `dndCallback` only while the rows are the hand-made order - App.ControllerTable hangs jQuery UI
  #   `sortable` off exactly that, and drops the drag-handle column with it. An automatic mode is
  #   therefore a read-only preview of the order about to be stored.
  #
  # The rows on screen are read before the new ones replace them, so #itemsForCurrentMode can start
  #   the hand-made order from what the editor was just looking at.
  renderTable: ->
    objects = @itemsForCurrentMode(@displayedIds())

    table = new App.ControllerTable(
      pager: false
      baseColWidth: null
      dndCallback: if @isManual() then (-> true)
      overview: ['title']
      attribute_list: [
        { name: 'title', display: __('Name') }
      ]
      objects: objects
    )

    @view.find('.js-table-container').html(table.el)

  # Dragging picks up where the last mode left off: switching to drag & drop keeps the rows in the
  #   order they are on screen rather than snapping back to the positions that happen to be stored.
  #   That is also the order #save then sends, which is the contract both stacks share - arming
  #   `manual` means saying what the order is (Service::KnowledgeBase::Reorder::Base
  #   #ensure_order_for_manual!), so the list an editor puts on drag & drop keeps looking the way it
  #   looked when they switched. The desktop view stages the same order for the same reason (see
  #   `pendingChanges` in useKnowledgeBaseSorting.ts).
  #
  # An automatic mode ignores what was on screen: its order comes from the content itself.
  itemsForCurrentMode: (displayedIds) ->
    return @items if !@itemsForMode

    items = @itemsForMode(@mode)

    return items if !@isManual()

    @orderedBy(items, displayedIds)

  # Rows the given order does not mention keep their place behind the ones it does, so nothing can
  #   go missing between two modes - and on the first render, where nothing is on screen yet, the
  #   whole list comes back in the order the mode itself gave it.
  orderedBy: (items, ids) ->
    byId = {}
    byId[item.id] = item for item in items

    ordered = (byId[id] for id in ids when byId[id])
    ordered.concat(item for item in items when ids.indexOf(item.id) is -1)

  displayedIds: ->
    @$('tr.item').toArray().map (el) -> parseInt(el.dataset.id)

  # Without modes there is nothing but the hand-made order, which is what this modal did before it
  #   could pick one.
  isManual: ->
    !@modes or @mode is 'manual'

  selectMode: (e) ->
    e.preventDefault()

    mode = e.currentTarget.dataset.mode
    return if mode is @mode

    @mode = mode

    @$('.js-sortingMode').removeClass('active')
    $(e.currentTarget).addClass('active')

    @renderTable()

  onShown: ->
    super
    @$('.js-submit').trigger('focus')

  save: ->
    data = {}
    data.sorting_mode = @mode if @mode

    # Only the hand-made order is ever sent: the endpoint refuses an order against an automatic mode,
    #   which derives its own order from the content.
    data.ordered_ids = @displayedIds() if @isManual()

    @$('.alert').addClass('hidden')

    @formDisable(@el)

    @ajax(
      id: 'reorder_save'
      type: 'PATCH'
      data: JSON.stringify(data)
      url: @url
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data)
        App.Event.trigger 'knowledge_base::sidebar::rerender'

        # A mode lives on the node above the list, so a save that only picked one changes no record
        #   *in* it - and the listeners that would redraw a list, App.KnowledgeBaseReaderListItem's
        #   among them, are bound to those records. Nothing would fire. This ping is what the
        #   containers reading the mode listen on instead
        #   (App.KnowledgeBaseReaderListContainer#parentRefreshed and the previous/next links under
        #   an answer), so the order changes where it is shown rather than at the next navigation.
        App.KnowledgeBase.trigger('kb_data_change_loaded')

        @close()
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @$('.alert--danger').removeClass('hidden').text(data.error)
        @formEnable(@el)
    )

  onSubmit: ->
    super
    @save()
