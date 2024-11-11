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

    @html App.view('ticket_zoom/sidebar_checklist/show')(
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

  setDisabled: (node) ->
    $(node)
      .closest('tr')
      .attr('disabled', true)
      .addClass('u-unclickable u-low-opacity')

  setEnabled: (node) ->
    $(node)
      .closest('tr')
      .attr('disabled', false)
      .removeClass('u-unclickable u-low-opacity')

    if @actionController instanceof ChecklistReorder
      @toggleReorder(true)

  onAdd: (e) =>
    addButton = e.target.closest('button')

    $(addButton).attr('disabled', true)

    item = new App.ChecklistItem
    item.checklist_id = @checklist.id
    item.text = ''

    self = @

    item.save(
      done: (data) ->
        self.addNewItem(@)

        $(addButton).attr('disabled', false)
      fail: (settings, details) =>
        $(addButton).attr('disabled', false)
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error)
        )
        @renderTable()
    )

  addNewItem: (item) ->
    row = $(App.view('ticket_zoom/sidebar_checklist/show_row')(
      object: item
    ))

    @checklist.sorted_item_ids.push item.id.toString()
    @moveOrInsertRow(item.id.toString(), row[0])

    @updateDisplayValue(item)

    row.data('text-value', '')

    cell = row.find('.checklistItemValue')[0]

    @activateItemEditMode(cell, row, item.id)

    @table.find('.checklistShowRowContentCellNoItems').remove()

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

    $(checkboxElem)
      .closest('tr')
      .find('.checkbox-replacement-readonly')
      .html(App.Utils.icon(if upcomingState then 'checkbox-checked-readonly' else 'checkbox-readonly'))

    @setDisabled(checkboxElem)

    item.save(
      done: =>
        @setEnabled(checkboxElem)
      fail: =>
        @setEnabled(checkboxElem)
        item.checked = !upcomingState
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
    return if e?.target && $(e.target).closest('th').find('.js-input').length

    @preventDefaultAndStopPropagation(e)

    # Close any open dropdowns
    @el.find('.dropdown--actions.open').dropdown('toggle')

    if e
      elem = e.currentTarget
    else
      elem = @el.find('.js-title')[0]

    @isRenamingChecklist = new App.SidebarChecklistRename(el: elem, parentVC: @, originalValue: @checklistTitle())

  onEntryTextClicked: (e) =>
    @table
      .find('.js-table-action-menu:visible')
      .dropdown('toggle')

    return if $(e.target).closest('td').find('.js-input').length

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
      @setDisabled(e.currentTarget)

      item.destroy(
        done: =>
          @table
            .find("tbody tr[data-id='#{id}']")
            .remove()

          if !@table.find('tbody tr[data-id]').length
            @renderEmpty()
        fail: =>
          @setEnabled(e.currentTarget)
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
    # @actionController?.releaseController()
    new App.SidebarChecklistItemEdit(
      el: cell
      parentVC: @
      id: id
    )

  renderEmpty: =>
    @table
      .find('tbody')
      .html(App.view('ticket_zoom/sidebar_checklist/show_no_items')())

  renderTable: ->
    @updateChecklistTitle()

    isReorderingInProgress = @actionController instanceof ChecklistReorder

    if !isReorderingInProgress
      @reorderButton.toggleClass('hide', @checklist.sorted_item_ids.length < 2)

    @parentVC.badgeRenderLocal()

    if !@checklist.sorted_item_ids.length
      @renderEmpty()
      return

    @table.find('.checklistShowRowContentCellNoItems').remove()

    @cleanUpDeleted()

    if!isReorderingInProgress
      @renderSorting()

    @renderDisplayValues()
    @renderSortable()
    @renderEditMode()

    if @actionController instanceof ChecklistReorder
      @toggleReorder(true)

  updateChecklistTitle: ->
    return if @isRenamingChecklist

    @table.find('th').html(@checklistTitle())

  renderSorting: =>
    for id, current_index in @checklist.sorted_item_ids
      @renderSortingSingle(id, current_index)

  renderSortingSingle: (id, current_index) =>
    row    = @table.find("tbody tr[data-id=#{id}]")
    object = App.ChecklistItem.find(id)

    if row.length and current_index != row.index().toString()
      @moveOrInsertRow(id, row)
      return

    row = $(App.view('ticket_zoom/sidebar_checklist/show_row')(
      object: object
    ))

    @updateDisplayValue(object)

    @moveOrInsertRow(id, row[0])

  renderDisplayValues: =>
    for id in @checklist.sorted_item_ids
      object = App.ChecklistItem.find(id)

      if !object
        continue

      row = @table.find("tbody tr[data-id=#{id}]")

      # Thisi s used for initial filling of an empty display value
      # This also works if an old checklist item is converted to a ticket reference.
      # The ticket reference cannot be converted back to a text item so opposite conversion is not needed.
      if object.ticket_id || row.find('.checklistShowRowDisplayValue').is(':empty')
        @updateDisplayValue(object)
        @setEnabled(row)
      else
        row
          .find('input.js-checkbox')
          .prop('checked', object.checked)

        row
          .find('.checkbox-replacement-readonly')
          .html(App.Utils.icon(if object.checked then 'checkbox-checked-readonly' else 'checkbox-readonly'))

        @applyTextValue(object, row)

      # row
      #   .find('li[data-table-action=check],li[data-table-action=edit]')
      #   .toggleClass('hide', !!object.ticket_id)

  applyTextValue: (object, row, displayValue) =>
    text = if object.text
      App.Utils.linkify(object.text)
    else if @readonly
      '-'
    else
      ''

    row.data('text-value', text)

    return if row.find('.checklistItemEdit').length

    row.find('.checklistItemValue').html(text)
    @setEnabled(row)

  updateDisplayValue: (object) =>
    row = @table.find("tbody tr[data-id=#{object.id}]")

    if object.ticket_id
      ticket = App.Ticket.find(object.ticket_id)
      ticketAccess = if ticket then ticket.userGroupAccess('read') else false

    displayValue = App.view('ticket_zoom/sidebar_checklist/show_row_display_value')(
      object: object
      ticket: ticket
      ticketAccess: ticketAccess
      readOnly: @readOnly
    )

    row
      .find('li[data-table-action=check],li[data-table-action=edit]')
      .toggleClass('hide', !!object.ticket_id)

    row
      .find('.checklistShowRowDisplayValue')
      .html(displayValue)

    @applyTextValue(object, row)

  moveOrInsertRow: (id, row) =>
    target_index = @checklist.sorted_item_ids.indexOf(id)

    is_focused = $(row).find('.js-input').is(':focus')

    if is_focused
      $(row).data('skip-blur', true)

    if target_index == 0
      @table
        .find('tbody')
        .prepend(row)
    else
      preceding_id  = @checklist.sorted_item_ids[target_index - 1]

      @table
        .find("tbody tr[data-id=#{preceding_id}]")
        .after(row)

    if is_focused
      $(row).find('.js-input').focus()
      $(row).data('skip-blur', false)

  cleanUpDeleted: =>
    rendered_ids = @table
      .find('tbody tr')
      .toArray()
      .map (el) -> $(el).data('id')?.toString()

    for id in _.difference(rendered_ids, @checklist.sorted_item_ids)
      @table
        .find("tbody tr[data-id=#{id}]")
        .remove()

  renderEditMode: =>
    if @enterEditMode
      @enterEditMode   = undefined
      @enterEditModeId = @table.find('tbody tr:last-of-type').data('id')

    if @enterEditModeId
      cell                = @table.find("tbody tr[data-id='" + @enterEditModeId + "']").find('.checklistItemValue')[0]
      row                 = $(cell).closest('tr')
      return if !row.length
      @enterEditModeId = undefined
      @activateItemEditMode(cell, row, row.data('id'))

  renderSortable: =>
    dndOptions =
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true
      items:                'tr'
    @table.find('tbody').sortable(dndOptions)
    @table.find('tbody').sortable('disable')

class ChecklistReorder extends App.Controller
  constructor: ->
    super
    @render()

  releaseController: =>
    @parentVC.toggleReorder(false, 'cancel')
    @parentVC.actionController = undefined
    @parentVC.renderTable()

  completed: =>
    @parentVC.toggleReorder(false)
    @parentVC.actionController = undefined

  render: =>
    @parentVC.toggleReorder(true)

class ChecklistItemRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()
