class App.SidebarChecklistShow extends App.Controller
  events:
    'click .js-reorder':              'onReorder'
    'click .js-add':                  'onAdd'
    'click .js-save-order':           'onSaveOrder'
    'click .js-reset-order':          'onResetOrder'
    'click .js-action':               'onAction'
    'change .js-checkbox':            'onCheckboxClick'
    'click .js-title':                'onTitleChange'
    'click .js-checklist-item-edit':  'onActionButtonClicked'

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

    $('body').off('click').on('click', (e) =>
      return if @actionController && @actionController.constructor.name is 'ChecklistReorder'
      return if $(e.target).closest('.js-actions').length > 0
      return if $(e.target).closest('.checklistShowButtons div.btn').length > 0
      return if $(e.target).closest('.checkbox-replacement').length > 0

      @actionController?.releaseController()
    )

    @renderTable()

  checklistTitle: =>
    @checklist.name || App.i18n.translateInline('%s Checklist', App.Config.get('ticket_hook') + @parentVC.ticket.number)

  onReorder: (e) =>
    @preventDefaultAndStopPropagation(e)
    @actionController?.releaseController()
    @actionController = new ChecklistReorder(parentVC: @)

  onAdd: (e) =>
    @addButton.attr('disabled', true)

    callbackDone = (data) =>
      @enterEditModeId = data.id
      @renderTable()
      @parentVC.subscribe()
      @addButton.attr('disabled', false)

    item = new App.ChecklistItem
    item.checklist_id = @checklist.id
    item.text = ''

    @parentVC.increaseCounter()

    item.save(
      done: ->
        App.ChecklistItem.full(@id, callbackDone, force: true)
      fail: (settings, details) =>
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error)
        )
        @renderTable()
        @addButton.attr('disabled', false)
    )

  onCheckboxClick: (e) =>
    upcomingState = e.currentTarget.checked
    id = parseInt(e.currentTarget.value)

    e.currentTarget.disabled = true

    @updateChecklistItem(id, upcomingState, e.currentTarget)

  onCheckOrUncheck: (id, e) =>
    row  = $(e.currentTarget).closest('tr')
    checkbox = row.find('.js-checkbox')[0]

    upcomingState = !checkbox.checked

    checkbox.disabled = true

    @updateChecklistItem(id, upcomingState, checkbox)

  updateChecklistItem: (id, upcomingState, checkboxElem) =>
    item = App.ChecklistItem.find(id)
    item.checked = upcomingState

    @parentVC.increaseCounter() if upcomingState is false
    @parentVC.decreaseCounter() if upcomingState is true

    item.save(
      done: =>
        checkboxElem.disabled = false
        @renderTable()
      fail: =>
        @renderTable()
    )

  onSaveOrder: (e) =>
    @saveOrderButton.attr('disabled', true)

    sorted_item_ids = @table.find('tbody tr').toArray().map (elem) -> elem.dataset.id

    item = @checklist
    item.sorted_item_ids = sorted_item_ids
    item.save(
      done: (data) =>
        @actionController?.completed()
      fail: =>
        @notify(
          type: 'error'
          msg:  App.i18n.translateInline('Failed to save the order of the checklist items. Please try again.')
        )
        @saveOrderButton.attr('disabled', false)
    )

  onResetOrder: (e) =>
    @actionController?.releaseController()

  onAction: (e) =>
    e.stopPropagation()

    dropdown = $(e.currentTarget).closest('td').find('.js-table-action-menu')
    dropdown.dropdown('toggle')
    dropdown.off('click.dropdown').on('click.dropdown', '[data-table-action]', @onActionButtonClicked)
    dropdown.off('keyup.dropdown').on('keyup.dropdown', '[data-table-action]', @onActionButtonKeyup)

  onTitleChange: (e) =>
    e?.stopPropagation()
    return if @actionController && @actionController.constructor.name is 'ChecklistReorder'

    # Close any open dropdowns
    @el.find('.dropdown--actions.open').dropdown('toggle')

    if e
      elem = e.currentTarget
    else
      elem = @el.find('.js-title')[0]

    @actionController?.releaseController()
    @actionController = new ChecklistRenameEdit(el: elem, parentVC: @, originalValue: @checklistTitle())

  onActionButtonKeyup: (e) =>
    return if e.key isnt 'Enter'

    @onActionButtonClicked(e)

  onActionButtonClicked: (e) =>
    e?.stopPropagation()
    return if @actionController && @actionController.constructor.name is 'ChecklistReorder'

    id = $(e.currentTarget).parents('tr').data('id')
    name = e.currentTarget.getAttribute('data-table-action')

    if name is 'edit'

      # skip on link openings
      return if e.target.tagName is 'A' && $(e.target).parent().hasClass('checklistItemValue')
      @onEditChecklistItem(id, e)

    else if name is 'delete'
      @onDeleteChecklistItem(id, e)

    else if _.contains(['check', 'uncheck'], name)
      @onCheckOrUncheck(id, e)

  toggleReorder: (isReordering, disablingCommand = 'disable') =>
    @table.find('tbody').sortable(if isReordering then 'enable' else disablingCommand)

    @table.find('.draggable').toggleClass('hide', !isReordering)
    @table.find('.checkbox-replacement').toggleClass('hide', isReordering)
    @table.find('.checkbox-replacement-readonly').toggleClass('hide', !isReordering)
    @table.find('.dropdown').toggleClass('hide', isReordering)

    @reorderButton.toggleClass('hide', isReordering)
    @addButton.toggleClass('hide', isReordering)
    @saveOrderButton.toggleClass('hide', !isReordering)
    @resetOrderButton.toggleClass('hide', !isReordering)

  onEditChecklistItem: (id, e) =>
    @preventDefaultAndStopPropagation(e)

    return if @actionController && @actionController.constructor.name is 'ChecklistItemEdit' && @actionController.id == id

    row  = $(e.currentTarget).closest('tr')
    cell = row.find('.checklistItemValue')[0]

    @activateItemEditMode(cell, row, id)

  onDeleteChecklistItem: (id, e) =>
    @preventDefaultAndStopPropagation(e)

    row = $(e.currentTarget).closest('tr')

    dropdown = $(e.currentTarget).closest('td').find('.js-table-action-menu')
    dropdown.dropdown('toggle')

    item = App.ChecklistItem.find(id)

    deleteCallback = =>
      @parentVC.decreaseCounter() if not item.checked

      item.destroy(
        done: =>
          @renderTable()
          @parentVC.subscribe()
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
      ticket = undefined
      ticketAccess = undefined
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
      @enterEditModeId = undefined
      @activateItemEditMode(cell, row, row.data('id'))

    @parentVC.badgeRenderLocal()

class ChecklistItemEdit extends App.Controller
  elements:
    '.js-input': 'input'
  events:
    'click .js-cancel':             'onCancel'
    'click .js-confirm':            'onConfirm'
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

  onCancel: (e) =>
    @preventDefaultAndStopPropagation(e)
    @releaseController()

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)

    item = @object()
    item.text = @input.val()
    item.save(
      done: =>
        @parentVC.renderTable()
        @parentVC.parentVC.subscribe()
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
      when 'Enter' then @onConfirm()
      when 'Escape' then @releaseController()

class ChecklistRenameEdit extends App.Controller
  elements:
    '.js-input': 'input'
  events:
    'click .js-cancel':               'onCancel'
    'click .js-confirm':              'onConfirm'
    'keyup #checklistTitleEditText':  'onKeyUp'

  constructor: ->
    super
    @render()

  releaseController: =>
    super
    @el.text(@originalValue)
    @parentVC.actionController = undefined

  render: =>
    @html App.view('ticket_zoom/sidebar_checklist_title_edit')(
      value: @object()?.name
      ticketNumber: @parentVC.parentVC.ticket.number
    )
    @input.focus().val('').val(@object()?.name)

  object: =>
    @parentVC.checklist

  onCancel: (e) =>
    @preventDefaultAndStopPropagation(e)
    @releaseController()

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)

    checklist = @object()
    checklist.name = @input.val()
    checklist.save(
      done: =>
        @parentVC.render()
    )

  onKeyUp: (e) =>
    switch e.key
      when 'Enter' then @onConfirm()
      when 'Escape' then @onCancel()

class ChecklistReorder extends App.Controller
  constructor: ->
    super
    @render()

  releaseController: =>
    @parentVC.toggleReorder(false, 'cancel')
    @parentVC.saveOrderButton.attr('disabled', false)
    @parentVC.actionController = undefined

  completed: =>
    @parentVC.toggleReorder(false)
    @parentVC.saveOrderButton.attr('disabled', false)
    @parentVC.actionController = undefined

  render: =>
    @parentVC.toggleReorder(true)

class ChecklistItemRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()
