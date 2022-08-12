class App.TicketBatch extends App.Controller
  requiredPermission: 'ticket.agent'

  mouse:
    x: null
    y: null
  batchAnimationPaused: false

  elements:
    '.js-batch-overlay-backdrop':   'batchOverlayBackdrop'
    '.js-batch-cancel':             'batchCancel'
    '.js-batch-macro-circle':       'batchMacroCircle'
    '.js-batch-assign-circle':      'batchAssignCircle'
    '.js-batch-assign':             'batchAssign'
    '.js-batch-assign-inner':       'batchAssignInner'
    '.js-batch-assign-group':       'batchAssignGroup'
    '.js-batch-assign-group-name':  'batchAssignGroupName'
    '.js-batch-assign-group-inner': 'batchAssignGroupInner'
    '.js-batch-macro':              'batchMacro'

  events:
    'mouseenter .js-batch-hover-target': 'highlightBatchEntry'
    'mouseleave .js-batch-hover-target': 'unhighlightBatchEntry'

  constructor: ->
    super

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', @render)
    @render()

  render: =>
    @html App.view('ticket_overview/batch_overlay')()
    @parentEl.off('mousedown.TicketBatch').on('mousedown.TicketBatch', '.item', @startDragItem)

  renderOptions: =>
    @renderOptionsGroups()
    @renderOptionsMacros()

  renderOptionsGroups: =>
    @batchAssignInner.html $(App.view('ticket_overview/batch_overlay_user_group')(
      @parent.validUsersForTicketSelection()
    ))

  renderOptionsMacros: =>

    @possibleMacros = []
    macros          = App.Macro.getList()

    items = @parentEl.find('[name="bulk"]:checked')

    group_ids =[]
    for item in items
      ticket = App.Ticket.find($(item).val())
      group_ids.push ticket.group_id

    group_ids = _.uniq(group_ids)

    for macro in macros

      # push if no group_ids exists
      if _.isEmpty(macro.group_ids) && !_.includes(@possibleMacros, macro)
        @possibleMacros.push macro

      # push if group_ids are equal
      if _.isEqual(macro.group_ids, group_ids) && !_.includes(@possibleMacros, macro)
        @possibleMacros.push macro

      # push if all group_ids of tickets are in macro.group_ids
      if !_.isEmpty(macro.group_ids) && _.isEmpty(_.difference(group_ids,macro.group_ids)) && !_.includes(@possibleMacros, macro)
        @possibleMacros.push macro

    @batchMacro.html $(App.view('ticket_overview/batch_overlay_macro')(
      macros: @possibleMacros
    ))

  startDragItem: (event) =>
    event.preventDefault()

    @grabbedItem      = $(event.currentTarget)
    offset            = @grabbedItem.offset()
    @batchDragger     = $(App.view('ticket_overview/batch_dragger')())
    @grabbedItemClone = @grabbedItem.clone()
    @grabbedItemClone.data('offset', @grabbedItem.offset())
    @grabbedItemClone.addClass('batch-dragger-item js-main-item')
    @batchDragger.append @grabbedItemClone

    @batchDragger.data
      startX: event.pageX
      startY: event.pageY
      dx: Math.min(event.pageX - offset.left, 180)
      dy: event.pageY - offset.top
      moved: false

    $(document).on 'mousemove.item', @dragItem
    $(document).one 'mouseup.item', @endDragItem
    # TODO: fire @cancelDrag on ESC

  dragItem: (event) =>
    pos = @batchDragger.data()
    threshold = 3
    x = event.pageX - pos.dx
    y = event.pageY - pos.dy
    dir = if event.pageY > pos.startY then 1 else -1

    if !pos.moved
      if Math.abs(event.pageY - pos.startY) > threshold || Math.abs(event.pageX - pos.startX) > threshold
        @batchDragger.data 'moved', true
        @el.addClass('u-no-userselect')
        # check grabbed items batch checkbox to make sure its checked
        # (could be grabbed without checking the checkbox it)
        @grabbedItemWasntChecked = !@grabbedItem.find('[name="bulk"]').prop('checked')
        @grabbedItem.find('[name="bulk"]').prop('checked', true)
        @grabbedItemClone.find('[name="bulk"]').prop('checked', true)

        additionalItems = @el.find('[name="bulk"]:checked').parents('.item').not(@grabbedItem)
        additionalItemsClones = additionalItems.clone()
        @draggedItems = @grabbedItemClone.add(additionalItemsClones)
        # store offsets for later use
        additionalItemsClones.each (i, item) -> $(@).data('offset', additionalItems.eq(i).offset())
        @batchDragger.prepend additionalItemsClones.addClass('batch-dragger-item').get().reverse()
        if(additionalItemsClones.length)
          @batchDragger.find('.js-batch-dragger-count').text(@draggedItems.length)

        @renderOptions()

        @appEl.append(@batchDragger)

        @draggedItems.each (i, item) ->
          dx = $(item).data('offset').left - $(item).offset().left - x
          dy = $(item).data('offset').top - $(item).offset().top - y
          $.Velocity.hook item, 'translateX', "#{dx}px"
          $.Velocity.hook item, 'translateY', "#{dy}px"

        @alignDraggedItems(-dir)

        @mouseY = event.pageY
        @showBatchOverlay()
      else
        return

    event.preventDefault()

    $.Velocity.hook @batchDragger, 'translateX', "#{x}px"
    $.Velocity.hook @batchDragger, 'translateY', "#{y}px"

  endDragItem: (event) =>
    $(document).off 'mousemove.item'
    $(document).off 'mouseup.item'
    pos = @batchDragger.data()

    @clearDelay('clear-hovered-batch-entry')

    if !@hoveredBatchEntry
      @cleanUpDrag()
      return

    $.Velocity.hook @batchDragger, 'transformOriginX', "#{pos.dx}px"
    $.Velocity.hook @batchDragger, 'transformOriginY', "#{pos.dy}px"
    @hoveredBatchEntry.velocity
      properties:
        scale: 1.1
      options:
        duration: 200
        complete: =>
          if !@hoveredBatchEntry
            @cleanUpDrag()
            return

          @hoveredBatchEntry.velocity 'reverse',
            duration: 200
            complete: =>

              if !@hoveredBatchEntry
                @cleanUpDrag()
                return

              # clean scale
              action = @hoveredBatchEntry.attr('data-action')
              id = @hoveredBatchEntry.attr('data-id')
              groupId = @hoveredBatchEntry.attr('data-group-id')
              items = @parentEl.find('[name="bulk"]:checked')
              @hoveredBatchEntry.removeAttr('style')
              @cleanUpDrag(true)

              @performBatchAction items, action, id, groupId
    @batchDragger.velocity
      properties:
        scale: 0
      options:
        duration: 200

  cancelDrag: ->
    $(document).off 'mousemove.item'
    $(document).off 'mouseup.item'
    @cleanUpDrag()

  cleanUpDrag: (success) ->
    @hideBatchOverlay()
    @el.removeClass('u-no-userselect')
    $('.batch-dragger').remove()
    @hoveredBatchEntry = null

    if @grabbedItemWasntChecked
      @grabbedItem.find('[name="bulk"]').prop('checked', false)

    if success
      # uncheck all checked items
      @el.find('[name="bulk"]:checked').prop('checked', false)
      @el.find('[name="bulk_all"]').prop('checked', false)

  alignDraggedItems: (dir) ->
    @draggedItems.velocity
      properties:
        translateX: 0
        translateY: (i) => dir * i * @batchDragger.height()/2
      options:
        easing: 'ease-in-out'
        duration: 300

    @batchDragger.find('.js-batch-dragger-count').velocity
      properties:
        translateY: if dir < 0 then 0 else -@batchDragger.height()+8
      options:
        easing: 'ease-in-out'
        duration: 300

  performBatchAction: (items, action, id, groupId) ->
    ticket_ids = items.toArray().map (item) -> $(item).val()

    switch action
      when 'macro'
        path = 'macro'
        data =
          ticket_ids: ticket_ids
          macro_id:   id

      when 'user_assign'
        path = 'update'

        data =
          ticket_ids: ticket_ids
          attributes:
            owner_id: id

        if !_.isEmpty(groupId)
          data.attributes.group_id = groupId

      when 'group_assign'
        path = 'update'

        data =
          ticket_ids: ticket_ids
          attributes:
            group_id: id

    @parent.ajax_mass(path, data, @batchSuccess)

  showBatchOverlay: ->
    @el.addClass('is-visible')
    $('html').css('overflow', 'hidden')
    @batchOverlayBackdrop.velocity { opacity: [1, 0] }, { duration: 500 }
    @batchMacroOffset = @batchMacro.offset().top + @batchMacro.outerHeight()
    @batchAssignOffset = @batchAssign.offset().top
    @batchOverlayShown = true
    $(document).on 'mousemove.batchoverlay', @controlBatchOverlay

  hideBatchOverlay: ->
    $(document).off 'mousemove.batchoverlay'
    @batchOverlayShown = false
    @batchOverlayBackdrop.velocity { opacity: [0, 1] }, { duration: 300, queue: false }
    @hideBatchCircles =>
      @el.removeClass('is-visible')

    $('html').css('overflow', '')

    if @batchAssignShown
      @hideBatchAssign()

    if @batchMacroShown
      @hideBatchMacro()

    if @batchAssignGroupShown
      @hideBatchAssignGroup()

  controlBatchOverlay: (event) =>
    return if @batchAnimationPaused
    # store to detect if the mouse is hovering a drag-action entry
    # after an animation ended -> @highlightBatchEntryAtMousePosition
    @mouse.x = event.pageX
    @mouse.y = event.pageY

    if @batchAssignGroupShown && @batchAssignGroupOffset != undefined
      if @mouse.y < @batchAssignGroupOffset
        @hideBatchAssignGroup()
        @batchAnimationPaused = true
      return

    if @mouse.y <= @batchMacroOffset
      mouseInArea = 'top'
    else if @mouse.y > @batchMacroOffset && @mouse.y <= @batchAssignOffset
      mouseInArea = 'middle'
    else
      mouseInArea = 'bottom'

    switch mouseInArea
      when 'top'
        if !@batchMacroShown
          @hideBatchCircles()
          @showBatchMacro()
          @alignDraggedItems(1)

      when 'middle'
        if @batchAssignShown
          @hideBatchAssign()

        if @batchMacroShown
          @hideBatchMacro()

        if !@batchCirclesShown
          @showBatchCircles()

      when 'bottom'
        if !@batchAssignShown
          @hideBatchCircles()
          @showBatchAssign()
          @alignDraggedItems(-1)

  showBatchCircles: ->
    @batchCirclesShown = true

    @batchMacroCircle.velocity
      properties:
        translateY: [0, '-150%']
        opacity: [1, 0]
      options:
        easing: [1,-.55,.2,1.37]
        duration: 500
        visibility: 'visible'
        delay: 200

    @batchAssignCircle.velocity
      properties:
        translateY: [0, '150%']
        opacity: [1, 0]
      options:
        easing: [1,-.55,.2,1.37]
        duration: 500
        visibility: 'visible'
        delay: 200

  hideBatchCircles: (callback) ->
    @batchMacroCircle.velocity
      properties:
        translateY: ['-150%', 0]
        opacity: [0, 1]
      options:
        duration: 300
        visibility: 'hidden'
        queue: false

    @batchAssignCircle.velocity
      properties:
        translateY: ['150%', 0]
        opacity: [0, 1]
      options:
        duration: 300
        complete: callback
        visibility: 'hidden'
        queue: false

    @batchCirclesShown = false

  showBatchAssign: ->
    return if !@batchOverlayShown # user might have dropped the item already
    @batchAssignShown = true

    @batchCancel.css
      top: 0
      bottom: @batchAssign.height()

    @batchAssign.velocity
      properties:
        translateY: [0, '100%']
        opacity: [1, 0]
      options:
        easing: [1,-.55,.2,1.37]
        duration: 500
        visibility: 'visible'
        complete: @highlightBatchEntryAtMousePosition

    @batchCancel.velocity
      properties:
        translateY: [0, '100%']
        opacity: [1, 0]
      options:
        easing: [1,-.55,.2,1.37]
        duration: 500
        visibility: 'visible'

  hideBatchAssign: ->
    @batchAssign.velocity
      properties:
        translateY: ['100%', 0]
        opacity: [0, 1]
      options:
        duration: 300
        visibility: 'hidden'
        queue: false
        complete: =>
          $.Velocity.hook @batchAssign, 'translateY', '0%'

    @batchCancel.velocity
      properties:
        translateY: ['100%', 0]
        opacity: [0, 1]
      options:
        duration: 300
        visibility: 'hidden'
        queue: false

    @batchAssignShown = false

  showBatchAssignGroup: =>
    return if !@batchOverlayShown # user might have dropped the item already
    @batchAssignGroupShown = true

    groupId = @hoveredBatchEntry.attr('data-id')
    group = App.Group.find(groupId)

    @batchAssignGroupName.text group.displayName()
    @batchAssignGroupInner.html $(App.view('ticket_overview/batch_overlay_user_group')(
      users: @parent.usersInGroups([groupId])
      groups: []
      groupId: groupId
    ))

    # then adjust the size of the group that it almost overlaps the batch-assign box
    @batchAssignGroupInner.height(@batchAssignInner.height())

    @batchAssignGroup.velocity
      properties:
        translateY: [0, '100%']
        opacity: [1, 0]
      options:
        easing: [1,-.55,.2,1.37]
        duration: 700
        visibility: 'visible'
        complete: =>
          @highlightBatchEntryAtMousePosition()
          @batchAssignGroupOffset = @batchAssignGroup.offset().top

  hideBatchAssignGroup: ->
    @batchAssignGroup.velocity
      properties:
        translateY: ['100%', 0]
        opacity: [0, 1]
      options:
        duration: 300
        visibility: 'hidden'
        queue: false
        complete: =>
          @batchAssignGroupShown = false
          @batchAssignGroupHovered = false
          setTimeout (=> @batchAnimationPaused = false), 1000

    @batchAssignGroupOffset = undefined

  showBatchMacro: ->
    return if !@batchOverlayShown # user might have dropped the item already
    @batchMacroShown = true

    @batchCancel.css
      bottom: 0
      top: @batchMacro.height()

    @batchMacro.velocity
      properties:
        translateY: [0, '-100%']
        opacity: [1, 0]
      options:
        easing: [1,-.55,.2,1.37]
        duration: 500
        visibility: 'visible'
        complete: @highlightBatchEntryAtMousePosition

    @batchCancel.velocity
      properties:
        translateY: [0, '-100%']
        opacity: [1, 0]
      options:
        easing: [1,-.55,.2,1.37]
        duration: 500
        visibility: 'visible'

  hideBatchMacro: ->
    @batchMacro.velocity
      properties:
        translateY: ['-100%', 0]
        opacity: [0, 1]
      options:
        duration: 300
        visibility: 'hidden'
        queue: false
        complete: =>
          $.Velocity.hook @batchMacro, 'translateY', '0%'

    @batchCancel.velocity
      properties:
        translateY: ['-100%', 0]
        opacity: [0, 1]
      options:
        duration: 300
        visibility: 'hidden'
        queue: false

    @batchMacroShown = false

  highlightBatchEntryAtMousePosition: =>
    entryAtPoint = $(document.elementFromPoint(@mouse.x, @mouse.y)).closest('.js-batch-overlay-entry .avatar')
    if(entryAtPoint.length)
      @hoveredBatchEntry = entryAtPoint.closest('.js-batch-overlay-entry').addClass('is-hovered')

  highlightBatchEntry: (event) =>
    @clearDelay('clear-hovered-batch-entry')
    @hoveredBatchEntry = $(event.currentTarget).closest('.js-batch-overlay-entry').addClass('is-hovered')

    if @hoveredBatchEntry.attr('data-action') is 'group_assign'
      @batchAssignGroupHintTimeout = setTimeout @blinkBatchEntry, 800
      @batchAssignGroupTimeout = setTimeout @showBatchAssignGroup, 900

  unhighlightBatchEntry: (event) ->
    return if !@hoveredBatchEntry
    if @hoveredBatchEntry.attr('data-action') is 'group_assign'
      if @batchAssignGroupTimeout
        clearTimeout @batchAssignGroupTimeout
      if @batchAssignGroupHintTimeout
        clearTimeout @batchAssignGroupHintTimeout

    @hoveredBatchEntry.removeClass('is-hovered')
    delay = =>
      @hoveredBatchEntry = null
    @delay(delay, 800, 'clear-hovered-batch-entry')

  blinkBatchEntry: =>
    @hoveredBatchEntry
      .velocity({ opacity: [0.5, 1] }, { duration: 120 })
      .velocity({ opacity: [1, 0.5] }, { duration: 60, delay: 40 })
      .velocity({ opacity: [0.5, 1] }, { duration: 120 })
      .velocity({ opacity: [1, 0.5] }, { duration: 60, delay: 40 })
