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

    @objects = @checklist.sorted_items()
    @render()

  render: ->
    @html App.view('ticket_zoom/sidebar_checklist_show')(
      checklistTitle: @checklistTitle()
      readOnly: @readOnly
    )

    @el.parent().off('click').on('click', (e) =>
      if @itemEditInProgress
        @clearEditWidget()
        @itemEditInProgress = false

      if @titleChangeInProgress
        @clearRenameWidget()
        @titleChangeInProgress = false
    )

    @renderTable()

    if @enterEditMode
      cell = @table.find('tr:last-of-type').find('.checklistItemValue')[0]
      row  = $(cell).closest('tr')

      @activateItemEditMode(cell, row, row.data('id'))

  checklistTitle: =>
    @checklist.name || App.i18n.translateInline('%s Checklist', App.Config.get('ticket_hook') + @parentVC.ticket.number)

  onReorder: (e) =>
    @clearEditWidget()
    @toggleReorder(true)

  onAdd: (e) =>
    @addButton.attr('disabled', true)
    @itemEditInProgress = true

    @ajax(
      id:   'checklist_item_create'
      type: 'POST'
      url:  "#{@apiPath}/tickets/#{@parentVC.ticket.id}/checklist/items"
      data: JSON.stringify({text: ''})
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @objects = @checklist.sorted_items()

        @clearEditWidget()
        @renderTable()
        cell = @table.find('tr:last-of-type').find('.checklistItemValue')[0]
        row  = $(cell).closest('tr')

        @activateItemEditMode(cell, row, data.id)

        @addButton.attr('disabled', false)
      error: =>
        @addButton.attr('disabled', false)
    )

  onCheckboxClick: (e) =>
    @clearEditWidget()
    upcomingState = e.currentTarget.checked
    id = parseInt(e.currentTarget.value)

    e.currentTarget.disabled = true

    @updateChecklistItem(id, upcomingState, e.currentTarget)

  onCheckOrUncheck: (id, e) =>
    row  = $(e.currentTarget).closest('tr')
    checkbox = row.find('.js-checkbox')[0]

    @clearEditWidget()
    upcomingState = !checkbox.checked

    checkbox.disabled = true

    @updateChecklistItem(id, upcomingState, checkbox)

  updateChecklistItem: (id, upcomingState, checkboxElem) =>
    @ajax(
      id:   'checklist_item_update_checked'
      type: 'PATCH'
      url:  "#{@apiPath}/tickets/#{@parentVC.ticket.id}/checklist/items/#{id}"
      data: JSON.stringify({checked: upcomingState})
      success: (data, status, xhr) =>
        object = _.find @objects, (elem) -> elem.id == id

        object.load(checked: upcomingState)

        checkboxElem.disabled = false
        @renderTable()
      error: ->
        checkboxElem.checked = !upcomingState
        checkboxElem.disabled = false
    )

  onSaveOrder: (e) =>
    @saveOrderButton.attr('disabled', true)

    sorted_item_ids = @table.find('tbody tr').toArray().map (elem) -> elem.dataset.id

    @ajax(
      id:   'checklist_update'
      type: 'PATCH'
      url:  "#{@apiPath}/tickets/#{@parentVC.ticket.id}/checklist"
      data: JSON.stringify({sorted_item_ids: sorted_item_ids})
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @toggleReorder(false)
        @saveOrderButton.attr('disabled', false)
      error: =>
        @saveOrderButton.attr('disabled', false)
    )

  onResetOrder: (e) =>
    @toggleReorder(false, 'cancel')

  onAction: (e) =>
    e.stopPropagation()

    if @itemEditInProgress
      @clearEditWidget()
      @itemEditInProgress = false

    if @titleChangeInProgress
      @clearRenameWidget()
      @titleChangeInProgress = false

    dropdown = $(e.currentTarget).closest('td').find('.js-table-action-menu')
    dropdown.dropdown('toggle')
    dropdown.on('click.dropdown', '[data-table-action]', @onActionButtonClicked)

  onTitleChange: (e) =>
    e?.stopPropagation()

    # Close any open dropdowns
    @el.find('.dropdown--actions.open').dropdown('toggle')

    if @itemEditInProgress
      @clearEditWidget()
      @itemEditInProgress = false

    return if @titleChangeInProgress

    if e
      elem = e.currentTarget
    else
      elem = @el.find('.js-title')[0]

    @clearRenameWidget()
    @renameWidget = new ChecklistRenameEdit(el: elem, parentVC: @, originalValue: @checklistTitle())

  onActionButtonClicked: (e) =>
    e?.stopPropagation()

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
    @table.find('.dropdown').toggleClass('hide', isReordering)

    @reorderButton.toggleClass('hide', isReordering)
    @addButton.toggleClass('hide', isReordering)
    @saveOrderButton.toggleClass('hide', !isReordering)
    @resetOrderButton.toggleClass('hide', !isReordering)

  onEditChecklistItem: (id, e) =>
    @preventDefaultAndStopPropagation(e)

    if @titleChangeInProgress
      @clearRenameWidget()
      @titleChangeInProgress = false

    return if @itemEditInProgress && @itemEditInProgress == id

    row  = $(e.currentTarget).closest('tr')
    cell = row.find('.checklistItemValue')[0]

    @clearEditWidget()

    @activateItemEditMode(cell, row, id)

  onDeleteChecklistItem: (id, e) =>
    @preventDefaultAndStopPropagation(e)

    row = $(e.currentTarget).closest('tr')

    dropdown = $(e.currentTarget).closest('td').find('.js-table-action-menu')
    dropdown.dropdown('toggle')

    item = App.ChecklistItem.find(id)

    deleteCallback = =>
      @ajax(
        id:   'checklist_item_delete'
        type: 'DELETE'
        url:  "#{@apiPath}/tickets/#{@parentVC.ticket.id}/checklist/items/#{id}"
        processData: true
        success: (data, status, xhr) =>
          App.ChecklistItem.find(id).remove(clear: true)

          @objects = @checklist.sorted_items()

          @clearEditWidget()
          @renderTable()
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
    $(cell).addClass('edit-widget-active')
    $(row).find('.dropdown').addClass('hide')

    @editWidget = new ChecklistItemEdit(
      el: cell
      parentVC: @
      originalValue: cell.textContent.trim()
      id: id
      cancelCallback: ->
        $(cell).removeClass('edit-widget-active')
        $(row).find('.dropdown').removeClass('hide')

        if $(row).find('.dropdown--actions').hasClass('open')
          $(row).find('.js-table-action-menu').dropdown('toggle')
    )

  clearEditWidget: =>
    @editWidget?.onCancel()
    @editWidget = undefined

  clearRenameWidget: =>
    @renameWidget?.onCancel()
    @renameWidget = undefined

  renderTable: ->
    @table.find('tbody').empty()

    for object in @objects
      html = App.view('ticket_zoom/sidebar_checklist_show_row')(
        object: object
        readOnly: @readOnly
      )

      @table.find('tbody').append(html)

    if !@objects.length
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

    @reorderButton.toggleClass('hide', !@objects.length || @objects.length < 2)

class ChecklistItemEdit extends App.Controller
  elements:
    '.js-input': 'input'
  events:
    'click .js-cancel':             'onCancel'
    'click .js-confirm':            'onConfirm'
    'keyup #checklistItemEditText': 'onKeyUp'

  constructor: ->
    super

    @parentVC.itemEditInProgress = @id

    @render()

  render: =>
    @html App.view('ticket_zoom/sidebar_checklist_item_edit')(value: @object()?.text)
    @input.focus().val('').val(@object()?.text)

  object: =>
    _.find @parentVC.objects, (elem) => elem.id == @id

  onCancel: (e) =>
    @preventDefaultAndStopPropagation(e)

    @release()
    @el.html(App.Utils.linkify(@originalValue))
    @parentVC.itemEditInProgress = null

    @cancelCallback() if @cancelCallback

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)

    @ajax(
      id:   'checklist_item_update_text'
      type: 'PATCH'
      url:  "#{@apiPath}/tickets/#{@parentVC.parentVC.ticket.id}/checklist/items/#{@id}"
      data: JSON.stringify({text: @input.val()})
      processData: true
      success: (data, status, xhr) =>
        @object().load(text: @input.val())

        @parentVC.clearEditWidget()
        @parentVC.renderTable()
        @parentVC.itemEditInProgress = null
    )

  onKeyUp: (e) =>
    switch e.key
      when 'Enter' then @onConfirm()
      when 'Escape' then @onCancel()

class ChecklistRenameEdit extends App.Controller
  elements:
    '.js-input': 'input'
  events:
    'click .js-cancel':               'onCancel'
    'click .js-confirm':              'onConfirm'
    'keyup #checklistTitleEditText':  'onKeyUp'

  constructor: ->
    super

    @parentVC.titleChangeInProgress = true

    @render()

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

    @release()
    @el.text(@originalValue)
    @parentVC.titleChangeInProgress = false

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)

    @ajax(
      id:   'checklist_title_update'
      type: 'PATCH'
      url:  "#{@apiPath}/tickets/#{@parentVC.parentVC.ticket.id}/checklist"
      data: JSON.stringify({name: @input.val()})
      processData: true
      success: (data, status, xhr) =>
        @object().load(name: @input.val())

        @parentVC.clearRenameWidget()
        @parentVC.render()
        @parentVC.titleChangeInProgress = false
    )

  onKeyUp: (e) =>
    switch e.key
      when 'Enter' then @onConfirm()
      when 'Escape' then @onCancel()

class ChecklistItemRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()
