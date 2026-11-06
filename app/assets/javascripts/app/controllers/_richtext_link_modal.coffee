# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.RichtextLinkModal extends App.ControllerModal
  buttonClose:  true
  buttonCancel: true
  small:        true

  events:
    'click .js-remove': 'removeLink'

  constructor: (params) ->
    @head = __('Link')
    @buttonSubmit = if params.existing then __('Update') else __('Link')
    @leftButtons = if params.existing then [{ text: __('Remove'), baseClass: 'btn--text btn--danger', className: 'js-remove' }] else []
    @url = if params.existing then $(params.existing).attr('href') or '' else ''
    @parentModal = params.editor.closest('.modal').data('bs.modal')

    super

  onShow: ->
    return unless @parentModal?.isShown

    # Bootstrap shares these global handlers between modal instances.
    $(window).off('keydown.dismiss.bs.modal resize.bs.modal')
    $(document).off('focusin.bs.modal')

  onClosed: ->
    return unless @parentModal?.isShown

    @parentModal.$body.addClass('modal-open')
    @parentModal.escape()
    @parentModal.resize()
    @parentModal.enforceFocus()
    @parentModal.handleUpdate()
    @editor.trigger('focus')

  content: ->
    "<input type=\"text\" name=\"link\" aria-label=\"#{App.i18n.translateInline('Link URL')}\" placeholder=\"http://\" value=\"#{App.Utils.htmlEscape(@url)}\">"

  onSubmit: =>
    url = @formParams().link.trim()

    if not url
      @showAlert(__('Enter link URL'))
      return

    @confirm(App.UiElement.richtext.ensureProtocol(url))
    @close()

  removeLink: (e) =>
    e.preventDefault()
    @remove()
    @close()
