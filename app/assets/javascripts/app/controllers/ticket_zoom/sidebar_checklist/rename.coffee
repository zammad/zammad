class App.SidebarChecklistRename extends App.Controller
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
    @parentVC.isRenamingChecklist = false

  render: =>
    @html App.view('ticket_zoom/sidebar_checklist/title_edit')(
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
    @parentVC.updateChecklistTitle()

  onConfirm: (e) =>
    @preventDefaultAndStopPropagation(e)

    newValue = @input.val()

    checklist = @object()

    if newValue == checklist.name
      @releaseController()
      @parentVC.updateChecklistTitle()
      return

    @parentVC.setDisabled(e.target)

    checklist.name = newValue
    checklist.save(
      done: =>
        @parentVC.setEnabled(e.target)
        @releaseController()
        @parentVC.updateChecklistTitle()
      fail: (settings, details) =>
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error)
        )

        @parentVC.setEnabled(e.target)
        @releaseController()
        @parentVC.updateChecklistTitle()
    )

  onKeyUp: (e) =>
    switch e.key
      when 'Enter' then @onConfirm(e)
      when 'Escape' then @onCancel(e)

