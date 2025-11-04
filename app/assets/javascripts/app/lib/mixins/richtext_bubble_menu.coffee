# Methods for initializing and using text tools in the richtext editor context.

App.RichtextBubbleMenu =
  richtextBubbleMenuInit: (el, disabled = false) ->
    return if disabled or (not @bubbleMenuEnabled() and not App.WidgetTextTools.enabled())

    ce = el.find('[contenteditable]').data().plugin_ce

    ce.onSelection (selection) =>
      el.parent().find('.js-bubbleMenu').remove()

      return if disabled
      return if not @bubbleMenuEnabled() and not App.WidgetTextTools.enabled()
      return if not selection.content

      # FIXME: This is a workaround to prevent the bubble menu from being shown for the plain text article types.
      #   Consider removing this once the plain text article types are fully supported.
      return if @type and @type isnt 'note' and @type isnt 'email' and @type isnt 'phone'

      actions = @filteredActions(ce)
      return if not actions.length

      bubbleElement = el.after($(App.view('generic/richtext_bubble_menu')(items: actions))).next()

      if range = selection.ranges[0]
        rect = range.getBoundingClientRect()
        parentOffset = el.parent().offset().left + el.parent().width()
        bubbleOffset = rect.left + bubbleElement.width()
        bubbleElement.offset({
          top: rect.top - bubbleElement.height() - 8

          # If the bubble menu would overflow the parent, move it to the left side of it.
          left: if bubbleOffset > parentOffset then parentOffset - bubbleElement.width() else rect.left
        })

      closeDropdown = ->
        bubbleElement.remove()

      bubbleElement.off('mousedown.bubble-menu', '.js-action').on('mousedown.bubble-menu', '.js-action', (e) =>
        e.preventDefault()

        actionNode = e.target.closest('.bubble-menu-item')
        actionKey = actionNode.dataset.key
        activeAction = _.find(@allActions(), (item) -> item.key is actionKey)

        activeAction.action(e, ce, selection, el) if activeAction

        return false
      )

      bubbleElement.addClass('open')

      bubbleMenuElement = bubbleElement.find('.bubble-menu')

      if not bubbleMenuElement.visible()
        offsetTop = 10
        header = el.closest('.content').find('.scrollPageHeader')
        if header.length and header.visible()
          offsetTop += header.height()
        bubbleMenuElement.ScrollTo({ offsetTop })

      setTimeout ->
        $(window).off('click.bubble-menu, keyup.bubble-menu').on 'click.bubble-menu, keyup.bubble-menu', (e) ->
          return if e.type is 'keyup' and e.key.startsWith('Shift')
          return if e.target.closest('.bubble-menu') # keep the bubble menu open if click is on the menu itself

          closeDropdown()
          $(window).off('click.bubble-menu, keyup.bubble-menu')

        el.one 'click.bubble-menu', (e) ->
          closeDropdown()
      , 100

  bubbleMenuEnabled: ->
    App.Config.get('ui_richtext_bubble_menu')

  allActions: ->
    [
      {
        type: 'dropup'
        key: 'ai-text-tools'
        label: __('Writing Assistant Tools')
        icon: 'smart-assist-elaborate'
        divider: true
        dividerClass: 'divider--full-height ai-vertical-gradient'
        show: (ce) ->
          App.WidgetTextTools.enabled() and App.WidgetTextTools.hasAvailableTextTools(ce)
        permission: 'ticket.agent'
        action: App.WidgetTextTools.renderDropdown
      },
      {
        key: 'bold'
        label: __('Format as bold')
        icon: 'type-bold'
        action: (e, ce) ->
          ce.executeFormattingAction('bold')
      },
      {
        key: 'italic'
        label: __('Format as italic')
        icon: 'type-italic'
        action: (e, ce) ->
          ce.executeFormattingAction('italic')
      },
      {
        key: 'underline'
        label: __('Format as underlined')
        icon: 'type-underline'
        action: (e, ce) ->
          ce.executeFormattingAction('underline')
      },
      {
        key: 'strikeThrough'
        label: __('Format as strikethrough')
        icon: 'type-strikethrough'
        action: (e, ce) ->
          ce.executeFormattingAction('strikeThrough')
      },
      {
        key: 'removeFormat'
        label: __('Remove formatting')
        icon: 'remove-formatting'
        divider: true
        action: (e, ce) ->
          ce.executeFormattingAction('removeFormat')
      },
      {
        key: 'h1'
        label: __('Heading 1')
        icon: 'type-h1'
        action: (e, ce) ->
          ce.toggleBlock('h1')
      },
      {
        key: 'h2'
        label: __('Heading 2')
        icon: 'type-h2'
        action: (e, ce) ->
          ce.toggleBlock('h2')
      },
      {
        key: 'h3'
        label: __('Heading 3')
        icon: 'type-h3'
        divider: true
        action: (e, ce) ->
          ce.toggleBlock('h3')
      },
      {
        key: 'insertOrderedList'
        label: __('Add ordered list')
        icon: 'list-ol'
        action: (e, ce) ->
          ce.executeFormattingAction('insertOrderedList')
      },
      {
        key: 'insertUnorderedList'
        label: __('Add unordered list')
        icon: 'list-ul'
        action: (e, ce) ->
          ce.executeFormattingAction('insertUnorderedList')
      },
    ]

  filteredActions: (ce) ->
    _.filter(@allActions(), (item) ->
      permissionCheck = item.permission is undefined or App.User.current()?.permission(item.permission)
      showCheck = item.show is undefined or (typeof item.show is 'function' and item.show(ce))
      permissionCheck and showCheck
    )
