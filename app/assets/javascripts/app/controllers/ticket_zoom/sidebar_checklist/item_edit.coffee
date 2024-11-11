class App.SidebarChecklistItemEdit extends App.Controller
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

    @el.removeClass('edit-widget-active')
    @el.closest('tr').find('.dropdown').removeClass('hide')

    if @el.closest('tr').find('.dropdown--actions').hasClass('open')
      @el.closest('tr').find('.js-table-action-menu').dropdown('toggle')

  render: =>
    @html App.view('ticket_zoom/sidebar_checklist/item_edit')(value: @object()?.text)

    @el.addClass('edit-widget-active')
    @el.closest('tr').find('.dropdown').addClass('hide')
    @input.focus().val('').val(@object()?.text)

  object: =>
    App.ChecklistItem.find(@id)

  onBlur: (e) =>
    return if @el.closest('tr').data('skip-blur')

    if $(e.originalEvent.relatedTarget).hasClass('js-cancel')
      @onCancel(e)
      return

    @onConfirm(e)

  onCancel: (e) =>
    @preventDefaultAndStopPropagation(e)
    @releaseController()
    row = @parentVC.table.find("tbody tr[data-id=#{@id}]")
    @el.text(row.data('text-value'))

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)

    newValue = @input.val()

    # Prevent AJAX if user has not changed the value
    row = @parentVC.table.find("tbody tr[data-id=#{@id}]")
    originalValue = row.data('text-value')

    if originalValue == newValue
      @releaseController()
      @el.text(originalValue)
      return

    item = @object()
    item.text = newValue

    @parentVC.setDisabled(row)

    item.save(
      done: =>
        @releaseController()
        @parentVC.updateDisplayValue(item)
        @parentVC.setEnabled(row)
      fail: (settings, details) =>
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error)
        )
        @releaseController()
        @parentVC.setEnabled(row)
        @parentVC.renderTable()
    )

  onKeyUp: (e) =>
    switch e.key
      when 'Enter' then @onConfirm(e)
      when 'Escape' then @onCancel(e)
