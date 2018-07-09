class App.TicketOverview extends App.Controller
  className: 'overviews'
  activeFocus: 'nav'
  mouse:
    x: null
    y: null
  batchAnimationPaused: false

  elements:
    '.js-batch-overlay':            'batchOverlay'
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
    '.main':                        'mainContent'

  events:
    'mousedown .item': 'startDragItem'
    'mouseenter .js-batch-hover-target': 'highlightBatchEntry'
    'mouseleave .js-batch-hover-target': 'unhighlightBatchEntry'

  constructor: ->
    super
    @batchSupport = @permissionCheck('ticket.agent')
    @render()

    # rerender view, e. g. on language change
    @bind 'ui:rerender', =>
      @renderBatchOverlay()

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
    @bindId = App.TicketCreateCollection.bind(load)

  startDragItem: (event) =>
    return if !@batchSupport
    @grabbedItem = $(event.currentTarget)
    offset = @grabbedItem.offset()
    @batchDragger = $(App.view('ticket_overview/batch_dragger')())
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

        $('#app').append @batchDragger

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
              items = @el.find('[name="bulk"]:checked')
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
    if action is 'macro'
      @batchCount = items.length
      @batchCountIndex = 0
      macro = App.Macro.find(id)
      for item in items
        #console.log "perform action #{action} with id #{id} on ", $(item).val()
        ticket = App.Ticket.find($(item).val())
        App.Ticket.macro(
          macro: macro.perform
          ticket: ticket
        )
        ticket.save(
          done: (r) =>
            @batchCountIndex++

            # refresh view after all tickets are proceeded
            if @batchCountIndex == @batchCount
              App.Event.trigger('overview:fetch')
        )
      return

    if action is 'user_assign'
      @batchCount = items.length
      @batchCountIndex = 0
      for item in items
        #console.log "perform action #{action} with id #{id} on ", $(item).val()
        ticket = App.Ticket.find($(item).val())
        ticket.owner_id = id
        if !_.isEmpty(groupId)
          ticket.group_id = groupId
        ticket.save(
          done: (r) =>
            @batchCountIndex++

            # refresh view after all tickets are proceeded
            if @batchCountIndex == @batchCount
              App.Event.trigger('overview:fetch')
        )
      return

    if action is 'group_assign'
      @batchCount = items.length
      @batchCountIndex = 0
      for item in items
        #console.log "perform action #{action} with id #{id} on ", $(item).val()
        ticket = App.Ticket.find($(item).val())
        ticket.group_id = id
        ticket.save(
          done: (r) =>
            @batchCountIndex++

            # refresh view after all tickets are proceeded
            if @batchCountIndex == @batchCount
              App.Event.trigger('overview:fetch')
        )
      return

  showBatchOverlay: ->
    @batchOverlay.addClass('is-visible')
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
      @batchOverlay.removeClass('is-visible')

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
      users: @usersInGroups([groupId])
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

  highlightBatchEntry: (event) ->
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

  usersInGroups: (group_ids) ->
    ids_by_group = _.chain(@formMeta?.dependencies?.group_id)
      .pick(group_ids)
      .values()
      .map( (e) -> e.owner_id)
      .value()

    # Underscore's intersection doesn't work when chained
    ids_in_all_groups = _.intersection(ids_by_group...)

    users = App.User.findAll(ids_in_all_groups)
    _.sortBy(users, (user) -> user.firstname)

  render: ->
    elLocal = $(App.view('ticket_overview/index')())

    @navBarControllerVertical = new Navbar(
      el:       elLocal.find('.overview-header')
      view:     @view
      vertical: true
    )

    @navBarController = new Navbar(
      el:   elLocal.filter('.sidebar')
      view: @view
    )

    @contentController = new Table(
      el:          elLocal.find('.overview-table')
      view:        @view
      keyboardOn:  @keyboardOn
      keyboardOff: @keyboardOff
    )

    @renderBatchOverlay(elLocal.filter('.js-batch-overlay'))

    @html elLocal

    @el.find('.main').on('click', =>
      @activeFocus = 'overview'
    )
    @el.find('.sidebar').on('click', =>
      @activeFocus = 'nav'
    )

    @bind('overview:fetch', =>
      return if !@view
      update = =>
        App.OverviewListCollection.fetch(@view)
      @delay(update, 2800, 'overview:fetch')
    )

  renderBatchOverlay: (elLocal) =>
    if elLocal
      elLocal.html( App.view('ticket_overview/batch_overlay')() )
      return
    @batchOverlay.html( App.view('ticket_overview/batch_overlay')() )
    @refreshElements()

  renderOptions: =>
    @renderOptionsGroups()
    @renderOptionsMacros()

  renderOptionsGroups: =>
    items = @el.find('[name="bulk"]:checked')

    # we want to display all users for which we can assign the tickets directly
    # for this we need to get the groups of all selected tickets
    # after we got those we need to check which users are available in all groups
    # users that are not in all groups can't get the tickets assigned
    ticket_ids       = _.map(items, (el) -> $(el).val() )
    ticket_group_ids = _.map(App.Ticket.findAll(ticket_ids), (ticket) -> ticket.group_id)
    users            = @usersInGroups(ticket_group_ids)

    # get the list of possible groups for the current user
    # from the TicketCreateCollection
    # (filled for e.g. the TicketCreation or TicketZoom assignment)
    # and order them by name
    group_ids     = _.keys(@formMeta?.dependencies?.group_id)
    groups        = App.Group.findAll(group_ids)
    groups_sorted = _.sortBy(groups, (group) -> group.name)

    # get the number of visible users per group
    # from the TicketCreateCollection
    # (filled for e.g. the TicketCreation or TicketZoom assignment)
    for group in groups
      group.valid_users_count = @formMeta?.dependencies?.group_id?[group.id]?.owner_id.length || 0

    @batchAssignInner.html $(App.view('ticket_overview/batch_overlay_user_group')(
      users: users
      groups: groups_sorted
    ))

  renderOptionsMacros: =>
    macros = App.Macro.search(filter: { active: true }, sortBy:'name', order:'DESC')

    @batchMacro.html $(App.view('ticket_overview/batch_overlay_macro')(
      macros: macros
    ))

  active: (state) =>
    return @shown if state is undefined
    @shown = state

  url: =>
    "#ticket/view/#{@view}"

  show: (params) =>
    @keyboardOn()

    # highlight navbar
    @navupdate '#ticket/view'

    # redirect to last overview if we got called in first level
    @view = params['view']
    if !@view && @viewLast
      @navigate "ticket/view/#{@viewLast}", true
      return

    # build nav bar
    if @navBarController
      @navBarController.update
        view:        @view
        activeState: true

    if @navBarControllerVertical
      @navBarControllerVertical.update
        view:        @view
        activeState: true

    # do not rerender overview if current overview is requested again
    return if @viewLast is @view

    # remember last view
    @viewLast = @view

    # build content
    @contentController = new Table(
      el:          @$('.overview-table')
      view:        @view
      keyboardOn:  @keyboardOn
      keyboardOff: @keyboardOff
    )

  hide: =>
    @keyboardOff()

    if @navBarController
      @navBarController.active(false)
    if @navBarControllerVertical
      @navBarControllerVertical.active(false)

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    @$('.main').scrollTop()

  changed: ->
    false

  release: =>
    @keyboardOff()
    super
    App.TicketCreateCollection.unbindById(@bindId)

  keyboardOn: =>
    $(window).off 'keydown.overview_navigation'
    $(window).on 'keydown.overview_navigation', @listNavigate

  keyboardOff: ->
    $(window).off 'keydown.overview_navigation'

  listNavigate: (e) =>

    # ignore if focus is in bulk action
    return if $(e.target).is('textarea, input, select')

    if e.keyCode is 38 # up
      e.preventDefault()
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      e.preventDefault()
      @nudge(e, 1)
      return
    else if e.keyCode is 32 # space
      e.preventDefault()
      if @activeFocus is 'overview'
        @$('.table-overview table tbody tr.is-hover td.js-checkbox-field label input').first().click()
    else if e.keyCode is 9 # tab
      e.preventDefault()
      if @activeFocus is 'nav'
        @activeFocus = 'overview'
        @nudge(e, 1)
      else
        @activeFocus = 'nav'
    else if e.keyCode is 13 # enter
      if @activeFocus is 'overview'
        location = @$('.table-overview table tbody tr.is-hover a').first().attr('href')
        if location
          @navigate location

  nudge: (e, position) ->

    if @activeFocus is 'overview'
      items = @$('.table-overview table tbody')
      current = items.find('tr.is-hover')

      if !current.size()
        items.find('tr').first().addClass('is-hover')
        return

      if position is 1
        next = current.next('tr')
        if next.size()
          current.removeClass('is-hover')
          next.addClass('is-hover')
      else
        prev = current.prev('tr')
        if prev.size()
          current.removeClass('is-hover')
          prev.addClass('is-hover')

      if next
        @scrollToIfNeeded(next, true)
      if prev
        @scrollToIfNeeded(prev, true)

    else
      # get current
      items = @$('.sidebar')
      current = items.find('li.active')

      if !current.size()
        location = items.find('li a').first().attr('href')
        if location
          @navigate location
        return

      if position is 1
        next = current.next('li')
        if next.size()
          @navigate next.find('a').attr('href')
      else
        prev = current.prev('li')
        if prev.size()
          @navigate prev.find('a').attr('href')

      if next
        @scrollToIfNeeded(next, true)
      if prev
        @scrollToIfNeeded(prev, true)

class Navbar extends App.Controller
  elements:
    '.js-tabsHolder': 'tabsHolder'
    '.js-tabsClone': 'clone'
    '.js-tabClone': 'tabClone'
    '.js-tabs': 'tabs'
    '.js-tab': 'tab'
    '.js-dropdown': 'dropdown'
    '.js-toggle': 'dropdownToggle'
    '.js-dropdownItem': 'dropdownItem'

  events:
    'click .js-tab': 'activate'
    'click .js-dropdownItem': 'navigateTo'
    'hide.bs.dropdown': 'onDropdownHide'
    'show.bs.dropdown': 'onDropdownShow'

  constructor: ->
    super

    @bindId = App.OverviewIndexCollection.bind(@render)

    # rerender view, e. g. on language change
    @bind 'ui:rerender', =>
      @render(App.OverviewIndexCollection.get())

    if @vertical
      $(window).on 'resize.navbar', @autoFoldTabs

  navigateTo: (event) ->
    location.hash = $(event.currentTarget).attr('data-target')

  onDropdownShow: =>
    @dropdownToggle.addClass('active')

  onDropdownHide: =>
    @dropdownToggle.removeClass('active')

  activate: (event) =>
    @tab.removeClass('active')
    $(event.currentTarget).addClass('active')

  release: =>
    if @vertical
      $(window).off 'resize.navbar', @autoFoldTabs
    App.OverviewIndexCollection.unbindById(@bindId)

  autoFoldTabs: =>
    items = App.OverviewIndexCollection.get()
    @html App.view("agent_ticket_view/navbar#{ if @vertical then '_vertical' }")
      items: items
      isAgent: @permissionCheck('ticket.agent')

    while @clone.width() > @tabsHolder.width()
      @tabClone.not('.hide').last().addClass('hide')
      @tab.not('.hide').last().addClass('hide')
      @dropdownItem.filter('.hide').last().removeClass('hide')

    # if all tabs are visible
    # remove dropdown and dropdown button
    if @dropdownItem.not('.hide').size() is 0
      @dropdown.remove()
      @dropdownToggle.remove()

  active: (state) =>
    @activeState = state

  update: (params = {}) ->
    for key, value of params
      @[key] = value
    @render(App.OverviewIndexCollection.get())

  render: (data) =>
    return if !data
    content = @el.closest('.content')
    if _.isArray(data) && _.isEmpty(data)
      content.find('.sidebar').addClass('hide')
      content.find('.main').addClass('hide')
      content.find('.js-error').removeClass('hide')
      @renderScreenError(
        el: @el.closest('.content').find('.js-error')
        detail:     'Currently no overview is assigned to your roles. Please contact your administrator.'
        objectName: 'Ticket'
      )
      return
    content.find('.sidebar').removeClass('hide')
    content.find('.main').removeClass('hide')
    content.find('.js-error').addClass('hide')

    # do not show vertical navigation if only one tab exists
    if @vertical
      if data && data.length <= 1
        @el.addClass('hidden')
      else
        @el.removeClass('hidden')

    # set page title
    if @activeState && @view && !@vertical
      for item in data
        if item.link is @view
          @title item.name, true

    # redirect to first view
    if @activeState && !@view && !@vertical
      view = data[0].link
      @navigate "ticket/view/#{view}", true
      return

    # add new views
    for item in data
      item.target = "#ticket/view/#{item.link}"
      if item.link is @view
        item.active = true
        activeOverview = item
      else
        item.active = false

    @html App.view("agent_ticket_view/navbar#{ if @vertical then '_vertical' else '' }")
      items: data

    if @vertical
      @autoFoldTabs()

class Table extends App.Controller
  events:
    'click [data-type=settings]': 'settings'
    'click [data-type=viewmode]': 'viewmode'

  constructor: ->
    super

    if @view
      @bindId = App.OverviewListCollection.bind(@view, @updateTable)

    # rerender view, e. g. on langauge change
    @bind 'ui:rerender', =>
      return if !@authenticateCheck()
      return if !@view
      @render(App.OverviewListCollection.get(@view))

  release: =>
    if @bindId
      App.OverviewListCollection.unbind(@bindId)

  update: (params) =>
    for key, value of params
      @[key] = value

    return if !@view

    if @view
      if @bindId
        App.OverviewListCollection.unbind(@bindId)
      @bindId = App.OverviewListCollection.bind(@view, @updateTable)

  updateTable: (data) =>
    if !@table
      @render(data)
      return

    # use cache
    overview = data.overview
    tickets  = data.tickets

    return if !overview && !tickets

    # get ticket list
    ticketListShow = []
    for ticket in tickets
      ticketListShow.push App.Ticket.find(ticket.id)
    @overview = App.Overview.find(overview.id)
    @table.update(
      overviewAttributes: @overview.view.s
      objects:            ticketListShow
      groupBy:            @overview.group_by
      groupDirection:     @overview.group_direction
      orderBy:            @overview.order.by
      orderDirection:     @overview.order.direction
    )

  render: (data) =>
    return if !data

    # use cache
    overview = data.overview
    tickets  = data.tickets

    return if !overview && !tickets

    @view_mode = App.LocalStorage.get("mode:#{@view}", @Session.get('id')) || 's'
    console.log 'notice', 'view:', @view, @view_mode

    # get ticket list
    ticketListShow = []
    for ticket in tickets
      ticketListShow.push App.Ticket.find(ticket.id)

    # if customer and no ticket exists, show the following message only
    if !ticketListShow[0] && @permissionCheck('ticket.customer')
      @html App.view('customer_not_ticket_exists')()
      return

    # set page title
    @overview = App.Overview.find(overview.id)

    # render init page
    checkbox = true
    edit     = false
    if @permissionCheck('admin.overview')
      edit = true
    if @permissionCheck('ticket.customer')
      checkbox = false
      edit     = false
    view_modes = [
      {
        name:  'S'
        type:  's'
        class: 'active' if @view_mode is 's'
      },
      {
        name:  'M'
        type:  'm'
        class: 'active' if @view_mode is 'm'
      }
    ]
    if @permissionCheck('ticket.customer')
      view_modes = []
    html = App.view('agent_ticket_view/content')(
      overview:   @overview
      view_modes: view_modes
      edit:       edit
    )
    html = $(html)

    @html html

    # create table/overview
    table = ''
    if @view_mode is 'm'
      table = App.view('agent_ticket_view/detail')(
        overview: @overview
        objects:  ticketListShow
        checkbox: checkbox
      )
      table = $(table)
      table.delegate('[name="bulk_all"]', 'change', (e) ->
        if $(e.currentTarget).prop('checked')
          $(e.currentTarget).closest('table').find('[name="bulk"]').prop('checked', true)
        else
          $(e.currentTarget).closest('table').find('[name="bulk"]').prop('checked', false)
      )
      @$('.table-overview').append(table)
    else
      openTicket = (id,e) =>

        # open ticket via task manager to provide task with overview info
        ticket = App.Ticket.findNative(id)
        App.TaskManager.execute(
          key:        "Ticket-#{ticket.id}"
          controller: 'TicketZoom'
          params:
            ticket_id:   ticket.id
            overview_id: @overview.id
          show:       true
        )
        @navigate ticket.uiUrl()
      callbackTicketTitleAdd = (value, object, attribute, attributes) ->
        attribute.title = object.title
        value
      callbackLinkToTicket = (value, object, attribute, attributes) ->
        attribute.link = object.uiUrl()
        value
      callbackUserPopover = (value, object, attribute, attributes) ->
        return value if !object
        refObjectId = undefined
        if attribute.name is 'customer_id'
          refObjectId = object.customer_id
        if attribute.name is 'owner_id'
          refObjectId = object.owner_id
        return value if !refObjectId
        attribute.class = 'user-popover'
        attribute.data =
          id: refObjectId
        value
      callbackOrganizationPopover = (value, object, attribute, attributes) ->
        return value if !object
        return value if !object.organization_id
        attribute.class = 'organization-popover'
        attribute.data =
          id: object.organization_id
        value
      callbackCheckbox = (id, checked, e) =>
        if @$('table').find('input[name="bulk"]:checked').length == 0
          @bulkForm.hide()
        else
          @bulkForm.show()

        if @lastChecked && e.shiftKey
          # check items in a row
          currentItem = $(e.currentTarget).parents('.item')
          lastCheckedItem = $(@lastChecked).parents('.item')
          items = currentItem.parent().children()

          if currentItem.index() > lastCheckedItem.index()
            # current item is below last checked item
            startId = lastCheckedItem.index()
            endId = currentItem.index()
          else
            # current item is above last checked item
            startId = currentItem.index()
            endId = lastCheckedItem.index()

          items.slice(startId+1, endId).find('[name="bulk"]').prop('checked', (-> !@checked))

        @lastChecked = e.currentTarget
      callbackIconHeader = (headers) ->
        attribute =
          name:        'icon'
          display:     ''
          translation: false
          width:       '28px'
          displayWidth:28
          unresizable: true
        headers.unshift(0)
        headers[0] = attribute
        headers
      callbackIcon = (value, object, attribute, header) ->
        value = ' '
        attribute.class  = object.iconClass()
        attribute.link   = ''
        attribute.title  = object.iconTitle()
        value

      @table = new App.ControllerTable(
        tableId:        "ticket_overview_#{@overview.id}"
        overview:       @overview.view.s
        el:             @$('.table-overview')
        model:          App.Ticket
        objects:        ticketListShow
        checkbox:       checkbox
        groupBy:        @overview.group_by
        groupDirection: @overview.group_direction
        orderBy:        @overview.order.by
        orderDirection: @overview.order.direction
        class: 'table--light'
        bindRow:
          events:
            'click': openTicket
        #bindCol:
        #  customer_id:
        #    events:
        #      'mouseover': popOver
        callbackHeader: [ callbackIconHeader ]
        callbackAttributes:
          icon:
            [ callbackIcon ]
          customer_id:
            [ callbackUserPopover ]
          organization_id:
            [ callbackOrganizationPopover ]
          owner_id:
            [ callbackUserPopover ]
          title:
            [ callbackLinkToTicket, callbackTicketTitleAdd ]
          number:
            [ callbackLinkToTicket, callbackTicketTitleAdd ]
        bindCheckbox:
          events:
            'click': callbackCheckbox
      )

    # start user popups
    @userPopups()

    # start organization popups
    @organizationPopups()

    @bulkForm = new BulkForm(
      holder: @el
      view: @view
    )

    # start bulk action observ
    @el.append(@bulkForm.el)
    if @$('.table-overview').find('input[name="bulk"]:checked').length isnt 0
      @bulkForm.show()

    # show/hide bulk action
    @$('.table-overview').delegate('input[name="bulk"], input[name="bulk_all"]', 'change', (e) =>
      if @$('.table-overview').find('input[name="bulk"]:checked').length == 0
        @bulkForm.hide()
        @bulkForm.reset()
      else
        @bulkForm.show()
    )

    # deselect bulk_all if one item is uncheck observ
    @$('.table-overview').delegate('[name="bulk"]', 'change', (e) =>
      bulkAll = @$('.table-overview').find('[name="bulk_all"]')
      checkedCount = @$('.table-overview').find('input[name="bulk"]:checked').length
      checkboxCount = @$('.table-overview').find('input[name="bulk"]').length
      if checkedCount is 0
        bulkAll.prop('indeterminate', false)
        bulkAll.prop('checked', false)
      else
        if checkedCount is checkboxCount
          bulkAll.prop('indeterminate', false)
          bulkAll.prop('checked', true)
        else
          bulkAll.prop('checked', false)
          bulkAll.prop('indeterminate', true)
    )

  viewmode: (e) =>
    e.preventDefault()
    @view_mode = $(e.target).data('mode')
    App.LocalStorage.set("mode:#{@view}", @view_mode, @Session.get('id'))
    @fetch()
    #@render()

  settings: (e) =>
    e.preventDefault()
    @keyboardOff()
    new App.OverviewSettings(
      overview_id:     @overview.id
      view_mode:       @view_mode
      container:       @el.closest('.content')
      onCloseCallback: @keyboardOn
    )

class BulkForm extends App.Controller
  className: 'bulkAction hide'

  events:
    'submit form':       'submit'
    'click .js-submit':  'submit'
    'click .js-confirm': 'confirm'
    'click .js-cancel':  'reset'

  constructor: ->
    super

    @configure_attributes_ticket = []
    used_attributes = ['state_id', 'pending_time', 'priority_id', 'group_id', 'owner_id']
    attributesClean = App.Ticket.attributesGet('edit')
    for attributeName, attribute of attributesClean
      if _.contains(used_attributes, attributeName)
        localAttribute = clone(attribute)
        localAttribute.nulloption = true
        localAttribute.default = ''
        localAttribute.null = true
        @configure_attributes_ticket.push localAttribute

    @holder = @options.holder
    @visible = false

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
      @render()
    @bindId = App.TicketCreateCollection.bind(load)

  release: =>
    App.TicketCreateCollection.unbind(@bindId)

  render: ->
    @el.css('right', App.Utils.getScrollBarWidth())

    @html(App.view('agent_ticket_view/bulk')())

    handlers = @Config.get('TicketZoomFormHandler')

    new App.ControllerForm(
      el: @$('#form-ticket-bulk')
      model:
        configure_attributes: @configure_attributes_ticket
        className:            'create'
        labelClass:           'input-group-addon'
      handlersConfig: handlers
      params:     {}
      filter:     @formMeta.filter
      formMeta:   @formMeta
      noFieldset: true
    )

    new App.ControllerForm(
      el: @$('#form-ticket-bulk-comment')
      model:
        configure_attributes: [{ name: 'body', display: 'Comment', tag: 'textarea', rows: 4, null: true, upload: false, item_class: 'flex' }]
        className:            'create'
        labelClass:           'input-group-addon'
      noFieldset: true
    )

    @confirm_attributes = [
      { name: 'type_id',  display: 'Type',       tag: 'select', multiple: false, null: true, relation: 'TicketArticleType', filter: @articleTypeFilter, default: '9', translate: true, class: 'medium' }
      { name: 'internal', display: 'Visibility', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, class: 'medium', item_class: '', default: false }
    ]

    new App.ControllerForm(
      el: @$('#form-ticket-bulk-typeVisibility')
      model:
        configure_attributes: @confirm_attributes
        className:            'create'
        labelClass:           'input-group-addon'
      noFieldset: true
    )

  articleTypeFilter: (items) ->
    for item in items
      if item.name is 'note'
        return [item]
    items

  confirm: =>
    @$('.js-action-step').addClass('hide')
    @$('.js-confirm-step').removeClass('hide')

    @makeSpaceForTableRows()

    # need a delay because of the click event
    setTimeout ( => @$('.textarea.form-group textarea').focus() ), 0

  reset: =>
    @cancel()

    if @visible
      @makeSpaceForTableRows()

  cancel: =>
    @$('.js-action-step').removeClass('hide')
    @$('.js-confirm-step').addClass('hide')

  show: =>
    @el.removeClass('hide')
    @visible = true
    @makeSpaceForTableRows()

  hide: =>
    @el.addClass('hide')
    @visible = false
    @removeSpaceForTableRows()

  makeSpaceForTableRows: =>
    height = @el.height()
    scrollParent = @holder.scrollParent()
    isScrolledToBottom = scrollParent.prop('scrollHeight') is scrollParent.scrollTop() + scrollParent.outerHeight()

    @holder.css('margin-bottom', height)

    if isScrolledToBottom
      scrollParent.scrollTop scrollParent.prop('scrollHeight') - scrollParent.outerHeight()

  removeSpaceForTableRows: =>
    @holder.css('margin-bottom', 0)

  ticketMergeParams: (params) ->
    ticketUpdate = {}
    for item of params
      if params[item] != '' && params[item] != null
        ticketUpdate[item] = params[item]

    # in case if a group is selected, set also the selected owner (maybe nobody)
    if params.group_id != '' && params.group_id != null
      ticketUpdate.owner_id = params.owner_id
    ticketUpdate

  submit: (e) =>
    e.preventDefault()

    @bulkCount = @holder.find('.table-overview').find('[name="bulk"]:checked').length

    if @bulkCount is 0
      App.Event.trigger 'notify', {
        type: 'error'
        msg: App.i18n.translateContent('At least one object must be selected.')
      }
      return

    ticket_ids = []
    @holder.find('.table-overview').find('[name="bulk"]:checked').each( (index, element) ->
      ticket_id = $(element).val()
      ticket_ids.push ticket_id
    )

    params = @formParam(e.target)

    for ticket_id in ticket_ids
      ticket = App.Ticket.find(ticket_id)

      ticketUpdate = @ticketMergeParams(params)
      ticket.load(ticketUpdate)

      # if title is empty - ticket can't processed, set ?
      if _.isEmpty(ticket.title)
        ticket.title = '-'

      # validate ticket
      errors = ticket.validate(
        screen: 'edit'
      )
      if errors
        @log 'error', 'update', errors
        errorString = ''
        for key, error of errors
          errorString += "#{key}: #{error}"

        @formValidate(
          form:   e.target
          errors: errors
          screen: 'edit'
        )

        App.Event.trigger 'notify', {
          type: 'error'
          msg: App.i18n.translateContent('Bulk action stopped %s!', errorString)
        }
        @cancel()
        return

    @bulkCountIndex = 0
    for ticket_id in ticket_ids
      ticket = App.Ticket.find(ticket_id)

      # update ticket
      ticketUpdate = @ticketMergeParams(params)

      # validate article
      if params['body']
        article = new App.TicketArticle
        params.from      = @Session.get().displayName()
        params.ticket_id = ticket.id
        params.form_id   = @form_id

        sender           = App.TicketArticleSender.findByAttribute('name', 'Agent')
        type             = App.TicketArticleType.find(params['type_id'])
        params.sender_id = sender.id

        if !params['internal']
          params['internal'] = false

        @log 'notice', 'update article', params, sender
        article.load(params)
        errors = article.validate()
        if errors
          @log 'error', 'update article', errors
          @formEnable(e)
          return

      ticket.load(ticketUpdate)

      # if title is empty - ticket can't processed, set ?
      if _.isEmpty(ticket.title)
        ticket.title = '-'

      ticket.save(
        done: (r) =>
          @bulkCountIndex++

          # reset form after save
          if article
            article.save(
              fail: (r) =>
                @log 'error', 'update article', r
            )

          # refresh view after all tickets are proceeded
          if @bulkCountIndex == @bulkCount
            @render()
            @hide()

            # fetch overview data again
            App.Event.trigger('overview:fetch')

        fail: (r) =>
          @bulkCountIndex++
          @log 'error', 'update ticket', r
          App.Event.trigger 'notify', {
            type: 'error'
            msg: App.i18n.translateContent('Can\'t update Ticket %s!', ticket.number)
          }
      )

    @holder.find('.table-overview').find('[name="bulk"]:checked').prop('checked', false)
    App.Event.trigger 'notify', {
      type: 'success'
      msg: App.i18n.translateContent('Bulk action executed!')
    }

class App.OverviewSettings extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  headPrefix: 'Edit'

  content: =>
    @overview = App.Overview.find(@overview_id)
    @head     = @overview.name

    @configure_attributes_article = []
    if @view_mode is 'd'
      @configure_attributes_article.push({
        name:     'view::per_page'
        display:  'Items per page'
        tag:      'select'
        multiple: false
        null:     false
        default: @overview.view.per_page
        options: {
          5: ' 5'
          10: '10'
          15: '15'
          20: '20'
          25: '25'
        },
      })

    @configure_attributes_article.push({
      name:      "view::#{@view_mode}"
      display:   'Attributes'
      tag:       'checkboxTicketAttributes'
      default:   @overview.view[@view_mode]
      null:      false
      translate: true
      sortBy:    null
    },
    {
      name:      'order::by'
      display:   'Order'
      tag:       'selectTicketAttributes'
      default:   @overview.order.by
      null:      false
      translate: true
      sortBy:    null
    },
    {
      name:      'order::direction'
      display:   'Order by Direction'
      tag:       'select'
      default:   @overview.order.direction
      null:      false
      translate: true
      options:
        ASC:  'up'
        DESC: 'down'
    },
    {
      name:       'group_by'
      display:    'Group by'
      tag:        'select'
      default:    @overview.group_by
      null:       true
      nulloption: true
      translate:  true
      options:    App.Overview.groupByAttributes()
    },
    {
      name:    'group_direction'
      display: 'Group by Direction'
      tag:     'select'
      default: @overview.group_direction
      null:    false
      translate: true
      options:
        ASC:   'up'
        DESC:  'down'
    },)

    controller = new App.ControllerForm(
      model:     { configure_attributes: @configure_attributes_article }
      autofocus: false
    )
    controller.form

  onClose: =>
    if @onCloseCallback
      @onCloseCallback()

  onSubmit: (e) =>
    params = @formParam(e.target)

    # check if re-fetch is needed
    @reload_needed = false
    if @overview.order.by isnt params.order.by
      @overview.order.by = params.order.by
      @reload_needed = true

    if @overview.order.direction isnt params.order.direction
      @overview.order.direction = params.order.direction
      @reload_needed = true

    if @overview.group_direction isnt params.group_direction
      @overview.group_direction = params.group_direction
      @reload_needed = true

    for key, value of params.view
      @overview.view[key] = value

    @overview.group_by = params.group_by

    @overview.save(
      done: =>

        # fetch overview data again
        if @reload_needed
          App.OverviewListCollection.fetch(@overview.link)
        else
          App.OverviewIndexCollection.trigger()
          App.OverviewListCollection.trigger(@overview.link)

        # close modal
        @close()
    )

class TicketOverviewRouter extends App.ControllerPermanent
  requiredPermission: ['ticket.agent', 'ticket.customer']

  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      view: params.view

    App.TaskManager.execute(
      key:        'TicketOverview'
      controller: 'TicketOverview'
      params:     clean_params
      show:       true
      persistent: true
    )

App.Config.set('ticket/view', TicketOverviewRouter, 'Routes')
App.Config.set('ticket/view/:view', TicketOverviewRouter, 'Routes')
App.Config.set('TicketOverview', { controller: 'TicketOverview', permission: ['ticket.agent', 'ticket.customer'] }, 'permanentTask')
App.Config.set('TicketOverview', { prio: 1000, parent: '', name: 'Overviews', target: '#ticket/view', key: 'TicketOverview', permission: ['ticket.agent', 'ticket.customer'], class: 'overviews' }, 'NavBar')
