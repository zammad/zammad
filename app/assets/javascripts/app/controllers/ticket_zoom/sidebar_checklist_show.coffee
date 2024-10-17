class App.SidebarChecklistShow extends App.Controller
  events:
    'click .js-reorder':              'onReorder'
    'click .js-add':                  'onAdd'
    'click .js-save-order':           'onSaveOrder'
    'click .js-reset-order':          'onResetOrder'
    'click .js-action':               'onAction'
    'change .js-checkbox':            'onCheckboxClick'
    'click .js-title':                'onTitleChange'
    'click .js-checklist-item-edit':  'onEntryTextClicked'

  elements:
    '.js-reorder':      'reorderButton'
    '.js-add':          'addButton'
    '.js-save-order':   'saveOrderButton'
    '.js-reset-order':  'resetOrderButton'
    'table':            'table'

  constructor: ->
    super

    @render()

  render: ->

    @html App.view('ticket_zoom/sidebar_checklist_show')(
      checklistTitle: @checklistTitle()
      readOnly: @readOnly
    )

    @renderTable()

  checklistTitle: =>
    @checklist.name || App.i18n.translateInline('%s Checklist', App.Config.get('ticket_hook') + @parentVC.ticket.number)

  onReorder: (e) =>
    @preventDefaultAndStopPropagation(e)
    @actionController?.releaseController()
    @actionController = new ChecklistReorder(parentVC: @)

  setDisabled: (node, id) ->
    $(node).closest("[data-id='" + id + "']").attr('disabled', true).addClass('u-unclickable u-low-opacity')

  onAdd: (e) =>
    addButton = e.target.closest('button')

    $(addButton).attr('disabled', true)

    callbackDone = (data) =>
      @enterEditModeId = data.id
      @renderTable()
      @parentVC.subscribe()
      $(addButton).attr('disabled', false)

    item = new App.ChecklistItem
    item.checklist_id = @checklist.id
    item.text = ''

    item.save(
      done: ->
        App.ChecklistItem.full(@id, callbackDone, force: true)
      fail: (settings, details) =>
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error)
        )
        @renderTable()
    )

  onCheckboxClick: (e) =>
    upcomingState = e.currentTarget.checked
    id = parseInt(e.currentTarget.value)

    @updateChecklistItem(id, upcomingState, e.currentTarget)

  onCheckOrUncheck: (e) =>
    @preventDefaultAndStopPropagation(e)

    row      = $(e.currentTarget).closest('tr')
    id       = row.data('id')
    checkbox = row.find('.js-checkbox')[0]

    upcomingState = !checkbox.checked

    @updateChecklistItem(id, upcomingState, checkbox)

  updateChecklistItem: (id, upcomingState, checkboxElem) =>
    item = App.ChecklistItem.find(id)
    item.checked = upcomingState

    @setDisabled(checkboxElem, id)

    item.save(
      done: =>
        @renderTable()
      fail: =>
        @renderTable()
    )

  onSaveOrder: (e) =>
    saveButton = e.target.closest('button')
    cancelButton = $(saveButton).prev()
    checklistTable = $(document).find('.checklistShow tbody')

    $(saveButton).attr('disabled', true)
    $(cancelButton).attr('disabled', true)
    $(checklistTable).addClass('u-unclickable u-low-opacity')

    sorted_item_ids = @table.find('tbody tr').toArray().map (elem) -> elem.dataset.id

    item = @checklist
    item.sorted_item_ids = sorted_item_ids
    item.save(
      done: (data) =>
        @actionController?.completed()
        $(saveButton).attr('disabled', false)
        $(cancelButton).attr('disabled', false)
        $(checklistTable).removeClass('u-unclickable u-low-opacity')


      fail: =>
        @notify(
          type: 'error'
          msg:  App.i18n.translateInline('Failed to save the order of the checklist items. Please try again.')
        )
        $(cancelButton).attr('disabled', false)
        $(saveButton).attr('disabled', false)
        $(checklistTable).removeClass('u-unclickable u-low-opacity')
    )

  onResetOrder: (e) =>
    @actionController?.releaseController()

  onAction: (e) =>
    e.stopPropagation()

    dropdown = $(e.currentTarget).closest('td').find('.js-table-action-menu')
    dropdown.dropdown('toggle')

    dropdown
      .off('click.dropdown')
      .on('click.dropdown', '[data-table-action=delete]', @onDeleteChecklistItem)
      .on('click.dropdown', '[data-table-action=edit]', @onEditChecklistItem)
      .on('click.dropdown', '[data-table-action=check]', @onCheckOrUncheck)

  onTitleChange: (e) =>
    @preventDefaultAndStopPropagation(e)

    # Close any open dropdowns
    @el.find('.dropdown--actions.open').dropdown('toggle')

    if e
      elem = e.currentTarget
    else
      elem = @el.find('.js-title')[0]

    @actionController?.releaseController()
    @actionController = new ChecklistRenameEdit(el: elem, parentVC: @, originalValue: @checklistTitle())

  onEntryTextClicked: (e) =>
    return if @actionController instanceof ChecklistItemEdit

    # skip on link openings
    return if e.target.tagName is 'A'

    @preventDefaultAndStopPropagation(e)

    @onEditChecklistItem(e)

  toggleSortability: (isSorting, disablingCommand = 'disable') =>
    @table.find('tbody').sortable(if isSorting then 'enable' else disablingCommand)

  toggleReorder: (isReordering, disablingCommand = 'disable') =>
    @toggleSortability(isReordering, disablingCommand)

    @table.find('.draggable').toggleClass('hide', !isReordering)
    @table.find('.checkbox-replacement').toggleClass('hide', isReordering)
    @table.find('.checkbox-replacement-readonly').toggleClass('hide', !isReordering)
    @table.find('.dropdown').toggleClass('hide', isReordering)
    @table.find('.checklistItemValue').toggleClass('js-checklist-item-edit u-clickable', !isReordering && !@readonly)

    @reorderButton.toggleClass('hide', isReordering)
    @addButton.toggleClass('hide', isReordering)
    @saveOrderButton.toggleClass('hide', !isReordering)
    @resetOrderButton.toggleClass('hide', !isReordering)

  onEditChecklistItem: (e) =>
    @preventDefaultAndStopPropagation(e)

    row  = $(e.currentTarget).closest('tr')
    id   = row.data('id')
    cell = row.find('.checklistItemValue')[0]

    @activateItemEditMode(cell, row, id)

  onDeleteChecklistItem: (e) =>
    @preventDefaultAndStopPropagation(e)

    row  = $(e.currentTarget).closest('tr')
    id   = row.data('id')

    dropdown = $(e.currentTarget).closest('td').find('.js-table-action-menu')
    dropdown.dropdown('toggle')

    item = App.ChecklistItem.find(id)

    deleteCallback = =>
      row.find('.checklistItemValue').css('text-decoration', 'line-through')

      @setDisabled(e.currentTarget, id)
      
      item.destroy(
        done: =>
          @renderTable()
          @parentVC.subscribe()
        fail: ->
          row.find('.checklistItemValue').css('text-decoration', 'auto')
      )

    # Skip confirmation dialog if the item has no text.
    if _.isEmpty(item.text)
      deleteCallback()
      return

    new ChecklistItemRemoveModal(
      item:      item
      container: @el.closest('.content')
      callback:  deleteCallback
    )

  activateItemEditMode: (cell, row, id) =>
    @actionController?.releaseController()
    @actionController = new ChecklistItemEdit(
      el: cell
      parentVC: @
      originalValue: cell.textContent.trim()
      id: id
    )

  renderTable: ->
    @table.find('tbody').empty()

    sorted_items = @checklist.sorted_items()

    for object in sorted_items
      if object.ticket_id
        ticket = App.Ticket.find(object.ticket_id)
        ticketAccess = if ticket then ticket.userGroupAccess('read') else false

      html = App.view('ticket_zoom/sidebar_checklist_show_row')(
        object: object
        ticket: ticket
        ticketAccess: ticketAccess
        readOnly: @readOnly
      )

      @table.find('tbody').append(html)

    if !sorted_items.length
      html = App.view('ticket_zoom/sidebar_checklist_show_no_items')()
      @table.find('tbody').append(html)

    dndOptions =
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true
      items:                'tr'
    @table.find('tbody').sortable(dndOptions)
    @table.find('tbody').sortable('disable')

    @reorderButton.toggleClass('hide', !sorted_items.length || sorted_items.length < 2)

    if @enterEditMode
      @enterEditMode   = undefined
      @enterEditModeId = @table.find('tbody tr:last-of-type').data('id')

    if @enterEditModeId
      cell                = @table.find("tbody tr[data-id='" + @enterEditModeId + "']").find('.checklistItemValue')[0]
      row                 = $(cell).closest('tr')
      return if !row.length
      @enterEditModeId = undefined
      @activateItemEditMode(cell, row, row.data('id'))

    @parentVC.badgeRenderLocal()

class ChecklistItemEdit extends App.Controller
  elements:
    '.js-input': 'input'
  events:
    'click .js-cancel':             'onCancel'
    'click .js-confirm':            'onConfirm'
    'blur .js-input':               'onBlur'
    'keyup #checklistItemEditText': 'onKeyUp'

  constructor: ->
    super
    @render()

  releaseController: =>
    super

    @el.text(@originalValue)
    @el.removeClass('edit-widget-active')
    @el.closest('tr').find('.dropdown').removeClass('hide')

    if @el.closest('tr').find('.dropdown--actions').hasClass('open')
      @el.closest('tr').find('.js-table-action-menu').dropdown('toggle')

    @parentVC.actionController = undefined

  render: =>
    @html App.view('ticket_zoom/sidebar_checklist_item_edit')(value: @object()?.text)

    @el.addClass('edit-widget-active')
    @el.closest('tr').find('.dropdown').addClass('hide')
    @input.focus().val('').val(@object()?.text)

  object: =>
    App.ChecklistItem.find(@id)

  setDisabled: (node, id) ->
    $(node).closest("[data-id='" + id + "']").attr('disabled', true).addClass('u-unclickable u-low-opacity')

  onBlur: (e) =>
    if $(e.originalEvent.relatedTarget).hasClass('js-cancel')
      @onCancel(e)
      return

    @onConfirm(e)

  onCancel: (e) =>
    @preventDefaultAndStopPropagation(e)
    @releaseController()

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)

    newValue = @input.val()

    # Prevent AJAX if user has not changed the value
    if @originalValue == newValue
      @releaseController()
      return
    item = @object()
    item.text = newValue

    @setDisabled(e.target, item.id)

    item.save(
      done: =>
        @parentVC.renderTable()
        @parentVC.parentVC.subscribe()
        @originalValue = newValue
      fail: (settings, details) =>
        App.ChecklistItem.fetch(id: item.id)

        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error)
        )
        @releaseController()
    )

  onKeyUp: (e) =>
    switch e.key
      when 'Enter' then @onConfirm(e)
      when 'Escape' then @releaseController()

class ChecklistRenameEdit extends App.Controller
  elements:
    '.js-input': 'input'
  events:
    'click .js-cancel':               'onCancel'
    'click .js-confirm':              'onConfirm'
    'blur .js-input':                 'onBlur'
    'keyup #checklistTitleEditText':  'onKeyUp'

  constructor: ->
    super
    @render()

  releaseController: =>
    super
    @el.text(@originalValue)
    @parentVC.actionController = undefined

  setDisabled: (node) ->
    $(node).closest('tr').attr('disabled', true).addClass('u-unclickable u-low-opacity')

  render: =>
    @html App.view('ticket_zoom/sidebar_checklist_title_edit')(
      value: @object()?.name
      ticketNumber: @parentVC.parentVC.ticket.number
    )
    @input.focus().val('').val(@object()?.name)

  object: =>
    @parentVC.checklist

  onBlur: (e) =>
    if $(e.originalEvent.relatedTarget).hasClass('js-cancel')
      @onCancel(e)
      return

    @onConfirm(e)

  onCancel: (e) =>
    @preventDefaultAndStopPropagation(e)
    @releaseController()

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)
    @setDisabled(e.target)

    checklist = @object()
    checklist.name = @input.val()
    checklist.save(
      done: =>
        @parentVC.render()
    )

  onKeyUp: (e) =>
    switch e.key
      when 'Enter' then @onConfirm(e)
      when 'Escape' then @onCancel()

class ChecklistReorder extends App.Controller
  constructor: ->
    super
    @render()

  releaseController: =>
    @parentVC.toggleReorder(false, 'cancel')
    @parentVC.actionController = undefined

  completed: =>
    @parentVC.toggleReorder(false)
    @parentVC.actionController = undefined

  render: =>
    @parentVC.toggleReorder(true)

class ChecklistItemRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()
