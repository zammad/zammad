class App.SidebarChecklistItemEdit extends App.Controller
  elements:
    '.js-input': 'input'
  events:
    'click .js-cancel':             'onCancel'
    'click .js-confirm':            'onConfirm'
    'blur .js-input':               'onBlur'
    'input .js-input':              'resize'
    'keydown .js-input':            'onKeyUp'

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
    @resize()

    if @caretOffset?
      position = Math.min(@caretOffset, @input.val().length)
      @input[0].setSelectionRange(position, position)

  resize: =>
    @input.css('height', 'auto')
    @input.css('height', @input.prop('scrollHeight') + @input.outerHeight() - @input.innerHeight())

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

    newValue = @input.val().trim()

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
    # Safari reports the keydown that commits an IME composition with keyCode 229, but not as composing.
    return if e.originalEvent?.isComposing or e.keyCode is 229

    switch e.key
      when 'Enter' then @onConfirm(e)
      when 'Escape' then @onCancel(e)
