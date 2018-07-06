class App.Controller extends Spine.Controller
  @include App.LogInclude

  constructor: (params) ->

    # unbind old bindlings
    if params && params.el && params.el.unbind
      params.el.unbind()

    super

    # generate controllerId
    @controllerId = 'controller-' + new Date().getTime() + '-' + Math.floor(Math.random() * 999999)

    # apply to release controller on dom remove
    @el.on('remove', @releaseController)
    @el.on('remove', @release)

    # create shortcuts
    @Config  = App.Config
    @Session = App.Session

    # create common accessors
    @apiPath = @Config.get('api_path')

    # remember ajax calls to abort them on dom release
    @ajaxCalls = []
    @ajax = (data) =>
      ajaxId = App.Ajax.request(data)
      @ajaxCalls.push ajaxId

  navigate: (location, hideCurrentLocationFromHistory = false) ->
    @log 'debug', "navigate to '#{location}', hide from history '#{hideCurrentLocationFromHistory}'"

    # hide current location from browser history, allow to use back button in browser
    if hideCurrentLocationFromHistory
      if window.history
        history = App.Config.get('History')
        oldLocation = history[history.length-2]
        if oldLocation
          window.history.replaceState(null, null, oldLocation)
    super location

  preventDefault: (e) ->
    e.preventDefault()

  bind: (event, callback) =>
    App.Event.bind(
      event
      callback
      @controllerId
    )

  unbind: (event, callback) =>
    App.Event.unbind(
      event
      callback
      @controllerId
    )

  clearDelay: (delay_id) =>
    App.Delay.clear(delay_id, @controllerId)

  delay: (callback, timeout, delay_id, queue = false) =>
    App.Delay.set(callback, timeout, delay_id, @controllerId, queue)

  clearInterval: (interval_id) =>
    App.Interval.clear(interval_id, @controllerId)

  interval: (callback, interval, interval_id, queue = false) =>
    App.Interval.set(callback, interval, interval_id, @controllerId, queue)

  releaseController: =>
    App.Event.unbindLevel(@controllerId)
    App.Delay.clearLevel(@controllerId)
    App.Interval.clearLevel(@controllerId)
    if @ajaxCalls
      for callId in @ajaxCalls
        App.Ajax.abort(callId)
    @userTicketPopupsDestroy()
    @ticketPopupsDestroy()
    @userPopupsDestroy()
    @organizationPopupsDestroy()

  release: ->
    # release custom bindings after it got removed from dom

  # add @title methode to set title
  title: (name, translate = false) ->
#    $('html head title').html(@Config.get(product_name) + ' - ' + App.i18n.translateInline(name))
    title = name
    if translate
      title = App.i18n.translatePlain(name)
    documentTitle = "#{@Config.get('product_name')} - #{title}"
    document.title = documentTitle
    App.Event.trigger('window-title-set', documentTitle)

  copyToClipboard: (text) ->
    if window.clipboardData # IE
      window.clipboardData.setData('Text', text)
    else
      window.prompt('Copy to clipboard: Ctrl+C, Enter', text)

  # disable all delay's and interval's
  disconnectClient: ->
    App.Delay.reset()
    App.Interval.reset()
    App.WebSocket.close(force: true)

  # add @notify methode to create notification
  notify: (data) ->
    App.Event.trigger 'notify', data

  # add @notifyDesktop methode to create desktop notification
  notifyDesktop: (data) ->
    App.Event.trigger 'notifyDesktop', data

  # add @navupdate methode to update navigation
  navupdate: (url, force = false) ->

    # ignore navupdate untill #clues are gone
    return if !force && window.location.hash is '#clues'

    App.Event.trigger 'navupdate', url

  # show navigation
  navShow: ->
    return if $('#navigation').is(':visible')
    $('#navigation').removeClass('hide')

  # hide navigation
  navHide: ->
    return if !$('#navigation').is(':visible')
    $('#navigation').addClass('hide')

  updateNavMenu: =>
    delay = ->
      App.Event.trigger('menu:render')
    @delay(delay, 150)

  closeTab: (key = @taskKey, dest) =>
    return if !key?
    App.TaskManager.remove(key)
    dest ?= App.TaskManager.nextTaskUrl() || '#'
    @navigate dest

  scrollTo: (x = 0, y = 0, delay = 0) ->
    a = ->
      window.scrollTo(x, y)

    @delay(a, delay)

  scrollToIfNeeded: (element, position = true) ->
    return if !element
    return if !element.get(0)
    if position is true
      return if element.visible(true)
    element.get(0).scrollIntoView(position)

  shake: (element) ->

    # this part is from wordpress 3, thanks to open source
    shakeMe = (element, position, positionEnd) ->
      positionStart = position.shift()
      element.css('left', positionStart + 'px')
      if position.length > 0
        setTimeout(->
          shakeMe(element, position, positionEnd)
        , positionEnd)
      else
        try
          element.css('position', 'static')
        catch e
          console.log 'error', e

    position = [ 15, 30, 15, 0, -15, -30, -15, 0 ]
    position = position.concat(position.concat(position))
    element.css('position', 'relative')
    shakeMe(element, position, 20)

  # get all params of the form
  formParam: (form) ->
    App.ControllerForm.params(form)

  formDisable: (form) ->
    App.ControllerForm.disable(form)

  formEnable: (form) ->
    App.ControllerForm.enable(form)

  formValidate: (data) ->
    App.ControllerForm.validate(data)

  # get all query params of the url
  queryParam: ->
    return if !@query
    pairs = @query.split(';')
    params = {}
    for pair in pairs
      result = pair.match('(.+?)=(.*)')
      if result && result[1]
        params[result[1]] = result[2]
    params

#  redirectToLogin: (data) ->
#

  # human readable file size
  humanFileSize: (size) ->
    App.Utils.humanFileSize(size)

  # human readable time
  humanTime: (time, escalation, long = true) ->
    App.PrettyDate.humanTime(time, escalation, long)

  userInfo: (data) ->
    el = data.el || $('[data-id="customer_info"]')
    el.unbind()

    # start customer info controller
    new App.WidgetUser(
      el:       el
      user_id:  data.user_id
      callback: data.callback
    )

  permissionCheckRedirect: (key, closeTab = false) ->
    return true if @permissionCheck(key)

    # remember requested url
    location = window.location.hash
    if location && location isnt '#login' && location isnt '#logout' && location isnt '#keyboard_shortcuts'
      App.Config.set('requested_url', location)

    if closeTab
      App.TaskManager.remove(@taskKey)

    # redirect to login
    @navigate '#login'

    throw "No permission for #{key}"

    false

  permissionCheck: (key) ->
    userId = App.Session.get('id')
    return false if !userId
    user = App.User.findNative(userId)
    return false if !user
    user.permission(key)

  authenticateCheckRedirect: ->
    return true if @authenticateCheck()

    # remember requested url
    location = window.location.hash
    if location && location isnt '#login' && location isnt '#logout' && location isnt '#keyboard_shortcuts'
      @Config.set('requested_url', location)

    # redirect to login
    @navigate '#login'

    throw 'No exsisting session'

    false

  authenticateCheck: ->
    # return true if session exists
    return true if @Session.get()
    false

  frontendTime: (timestamp, row = {}) ->
    if !row['subclass']
      row['subclass'] = ''
    "<span class=\"humanTimeFromNow #{row.subclass}\" data-time=\"#{timestamp}\">?</span>"

  frontendTimeUpdate: =>
    update = =>
      @frontendTimeUpdateElement($('#app'))
    App.Interval.set(update, 61000, 'frontendTimeUpdate', 'ui')

  frontendTimeUpdateElement: (el) =>
    ui = @
    el.find('.humanTimeFromNow').each( ->
      item = $(@)
      ui.frontendTimeUpdateItem(item, item.text())
    )

  frontendTimeUpdateItem: (item, currentVal) =>
    timestamp = item.data('time')
    time      = @humanTime(timestamp, item.hasClass('escalation'))

    # only do dom updates on changes
    return if time is currentVal
    item.attr('title', App.i18n.translateTimestamp(timestamp))
    item.html(time)

  ticketPopups: (position = 'right') ->

    # open ticket in new task if curent user agent
    if @permissionCheck('ticket.agent')
      @$('div.ticket-popover, span.ticket-popover').bind('click', (e) =>
        id = $(e.target).data('id')
        return if !id
        ticket = App.Ticket.findNative(id)
        @navigate ticket.uiUrl()
      )

    @ticketPopupsDestroy()

    # show ticket popup
    ui = @
    @ticketPopupsList = @el.find('.ticket-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      animation:  false
      delay:      100
      placement:  position
      title: ->
        ticketId = $(@).data('id')
        ticket   = App.Ticket.find(ticketId)
        App.Utils.htmlEscape(ticket.title)
      content: ->
        ticketId = $(@).data('id')
        ticket   = App.Ticket.fullLocal(ticketId)
        html = $(App.view('popover/ticket')(
          ticket: ticket
        ))
        html.find('.humanTimeFromNow').each(->
          ui.frontendTimeUpdateItem($(@))
        )
        html
    )

  ticketPopupsDestroy: =>
    if @ticketPopupsList
      @ticketPopupsList.popover('destroy')

  userPopups: (position = 'right') ->

    # open user in new task if current user is agent
    return if !@permissionCheck('ticket.agent')
    @$('div.user-popover, span.user-popover').bind('click', (e) =>
      id = $(e.target).data('id')
      return if !id
      user = App.User.findNative(id)
      @navigate user.uiUrl()
    )

    @userPopupsDestroy()

    # show user popup
    @userPopupsList = @el.find('.user-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      animation:  false
      delay:      100
      placement:  "auto #{position}"
      title: ->
        userId = $(@).data('id')
        user   = App.User.find(userId)
        headline = App.Utils.htmlEscape(user.displayName())
        if user.isOutOfOffice()
          headline += " (#{App.Utils.htmlEscape(user.outOfOfficeText())})"
        headline
      content: ->
        userId = $(@).data('id')
        user   = App.User.fullLocal(userId)

        # get display data
        userData = []
        for attributeName, attributeConfig of App.User.attributesGet('view')

          # check if value for _id exists
          name    = attributeName
          nameNew = name.substr(0, name.length - 3)
          if nameNew of user
            name = nameNew

          # add to show if value exists
          if user[name] && attributeConfig.shown

            # do not show firstname and lastname / already show via diplayName()
            if name isnt 'firstname' && name isnt 'lastname' && name isnt 'organization'
              userData.push attributeConfig

        # insert data
        App.view('popover/user')(
          user:     user
          userData: userData
        )
    )

  userPopupsDestroy: =>
    if @userPopupsList
      @userPopupsList.popover('destroy')

  organizationPopups: (position = 'right') ->

    # open org in new task if current user agent
    return if !@permissionCheck('ticket.agent')

    @$('div.organization-popover, span.organization-popover').bind('click', (e) =>
      id = $(e.target).data('id')
      return if !id
      organization = App.Organization.find(id)
      @navigate organization.uiUrl()
    )

    @organizationPopupsDestroy()

    # show organization popup
    @organizationPopupsList = @el.find('.organization-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      animation:  false
      delay:      100
      placement:  "auto #{position}"
      title: ->
        organization_id = $(@).data('id')
        organization    = App.Organization.find(organization_id)
        App.Utils.htmlEscape(organization.name)
      content: ->
        organization_id = $(@).data('id')
        organization    = App.Organization.fullLocal(organization_id)

        # get display data
        organizationData = []
        for attributeName, attributeConfig of App.Organization.attributesGet('view')

          # check if value for _id exists
          name    = attributeName
          nameNew = name.substr(0, name.length - 3)
          if nameNew of organization
            name = nameNew

          # add to show if value exists
          if organization[name] && attributeConfig.shown

            # do not show firstname and lastname / already show via diplayName()
            if name isnt 'name'
              organizationData.push attributeConfig

        # insert data
        App.view('popover/organization')(
          organization:     organization,
          organizationData: organizationData,
        )
    )

  organizationPopupsDestroy: =>
    if @organizationPopupsList
      @organizationPopupsList.popover('destroy')

  userTicketPopups: (params) ->

    show = (data, ticket_list) =>

      if !data.position
        data.position = 'left'

      @userTicketPopupsDestroy()

      # show user popup
      ui = @
      @userTicketPopupsList = @el.find(data.selector).popover(
        trigger:    'hover'
        container:  'body'
        html:       true
        animation:  false
        delay:      100
        placement:  "auto #{data.position}"
        title: ->
          $(@).find('[title="*"]').val()

        content: ->
          type = $(@).filter('[data-type]').data('type')
          tickets = []
          if ticket_list[type]
            for ticketId in ticket_list[type]
              tickets.push App.Ticket.fullLocal(ticketId)

          # insert data
          html = $(App.view('popover/user_ticket_list')(
            tickets: tickets
          ))
          html.find('.humanTimeFromNow').each( ->
            ui.frontendTimeUpdateItem($(@))
          )
          html
      )

    fetch = (params) =>
      @ajax(
        type:  'GET'
        url:   "#{@Config.get('api_path')}/ticket_customer"
        data:
          customer_id: params.user_id
        processData: true
        success: (data, status, xhr) ->
          App.Collection.loadAssets(data.assets)
          show(params, { open: data.ticket_ids_open, closed: data.ticket_ids_closed })
      )

    # get data
    fetch(params)

  userTicketPopupsDestroy: =>
    if @userTicketPopupsList
      @userTicketPopupsList.popover('destroy')

  anyPopoversDestroy: ->

    # do not remove permanent .popover--notifications widget
    $('.popover:not(.popover--notifications)').remove()

  recentView: (object, o_id) =>
    params =
      object: object
      o_id:   o_id
    App.Ajax.request(
      id:    "recent_view_#{object}_#{o_id}"
      type:  'POST'
      url:   @Config.get('api_path') + '/recent_view'
      data:  JSON.stringify(params)
      processData: true
    )

  prepareForObjectList: (items) ->
    for item in items
      item = @prepareForObjectListItem(item)
    items

  prepareForObjectListItem: (item) ->
    item.link  = ''
    item.title = '???'

    # convert backend name space to local name space
    item.object = item.object.replace('::', '')

    # lookup real data
    if App[item.object] && App[item.object].exists(item.o_id)
      object            = App[item.object].findNative(item.o_id)
      item.objectNative = object
      item.link         = object.uiUrl()
      item.title        = object.displayName()
      item.object_name  = object.objectDisplayName()
      item.cssIcon      = object.iconActivity(@Session.get())

    item.created_by = App.User.findNative(item.created_by_id)
    item

  stopPropagation: (e) ->
    e.stopPropagation()

  startLoading: (el) =>
    return if @initLoadingDone && !el
    @initLoadingDone = true
    @stopLoading()
    later = =>
      if el
        el.html App.view('generic/page_loading')()
      else
        @html App.view('generic/page_loading')()
    @initLoadingDoneDelay = @delay(later, 1800)

  stopLoading: =>
    return if !@initLoadingDoneDelay
    @clearDelay(@initLoadingDoneDelay)

  renderScreenSuccess: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/success')(data)

  renderScreenError: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/generic')(data)

  renderScreenNotFound: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/not_found')(data)

  renderScreenUnauthorized: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/unauthorized')(data)

  locationVerify: (e) =>
    newLocation = $(e.currentTarget).attr 'href'
    @log 'debug', "new location '#{newLocation}'"
    return if !newLocation
    @locationExecuteOrNavigate(newLocation)

  locationExecuteOrNavigate: (newLocation) =>
    currentLocation = Spine.Route.getPath()
    @log 'debug', "current location '#{currentLocation}'"
    if newLocation.replace(/#/, '') isnt currentLocation
      @log 'debug', "navigate to location '#{newLocation}'"
      @navigate(newLocation)
      return
    @locationExecute(newLocation)

  locationExecute: (newLocation) =>
    newLocation = newLocation.replace(/#/, '')
    @log 'debug', "execute controller again for '#{newLocation}' because of same hash"
    Spine.Route.matchRoutes(newLocation)

  logoUrl: ->
    "#{@Config.get('image_path')}/#{@Config.get('product_logo')}"

  selectAll: (e) ->
    e.currentTarget.focus()
    e.currentTarget.select()

  windowReload: (e,url) ->
    if e
      e.preventDefault()
    $('#app').hide().attr('style', 'display: none!important')
    if url
      window.location = url
      return true
    if window.location.reload
      window.location.reload()
      return true
    if window.location.href
      window.location.href = window.location.href
      return true

    throw 'Cant reload page!'

class App.ControllerPermanent extends App.Controller
  constructor: ->
    if @requiredPermission
      @permissionCheckRedirect(@requiredPermission, true)

    super

    @navShow()

class App.ControllerSubContent extends App.Controller
  constructor: ->
    if @requiredPermission
      @permissionCheckRedirect(@requiredPermission)

    super

  show: =>
    return if !@header
    @title @header, true

class App.ControllerContent extends App.Controller
  constructor: ->
    if @requiredPermission
      @permissionCheckRedirect(@requiredPermission)

    super

    # hide tasks
    App.TaskManager.hideAll()
    $('#content').removeClass('hide').removeClass('active')
    @navShow()

class App.ControllerModal extends App.Controller
  authenticateRequired: false
  backdrop: true
  keyboard: true
  large: false
  small: false
  head: '?'
  autoFocusOnFirstInput: true
  container: null
  buttonClass: 'btn--success'
  centerButtons: []
  leftButtons: []
  buttonClose: true
  buttonCancel: false
  buttonCancelClass: 'btn--text btn--subtle'
  buttonSubmit: true
  headPrefix: ''
  shown: true
  closeOnAnyClick: false
  initalFormParams: {}
  initalFormParamsIgnore: false
  showTrySupport: false
  showTryMax: 10
  showTrydelay: 1000

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-cancel':                   'cancel'
    'click .js-close':                    'cancel'

  className: 'modal fade'

  constructor: ->
    super
    @showTryCount = 0

    if @authenticateRequired
      return if !@authenticateCheckRedirect()

    # rerender view, e. g. on langauge change
    @bind('ui:rerender', =>
      @update()
      'modal'
    )
    if @shown
      @render()

  showDelayed: =>
    delay = =>
      @showTryCount += 1
      @render()
    @delay(delay, @showTrydelay)

  modalAlreadyExists: ->
    return true if $('.modal').length > 0
    false

  content: ->
    'You need to implement a one @content()!'

  update: =>
    if @message
      content = App.i18n.translateContent(@message)
    else if @contentInline
      content = @contentInline
    else
      content = @content()
    modal = $(App.view('modal')(
      head:              @head
      headPrefix:        @headPrefix
      message:           @message
      detail:            @detail
      buttonClose:       @buttonClose
      buttonCancel:      @buttonCancel
      buttonCancelClass: @buttonCancelClass
      buttonSubmit:      @buttonSubmit
      buttonClass:       @buttonClass
      centerButtons:     @centerButtons
      leftButtons:       @leftButtons
    ))
    modal.find('.modal-body').html(content)
    if !@initRenderingDone
      @initRenderingDone = true
      @html(modal)
    else
      @$('.modal-dialog').replaceWith(modal)
    @post()

  post: ->
    # nothing

  element: =>
    @el

  render: =>
    if @showTrySupport is true && @modalAlreadyExists() && @showTryCount <= @showTryMax
      @showDelayed()
      return

    @initalFormParamsIgnore = false

    if @buttonSubmit is true
      @buttonSubmit = 'Submit'
    if @buttonCancel is true
      @buttonCancel = 'Cancel & Go Back'

    @update()

    if @container
      @el.addClass('modal--local')
    if @veryLarge
      @el.addClass('modal--veryLarge')
    if @large
      @el.addClass('modal--large')
    if @small
      @el.addClass('modal--small')

    @el.modal(
      keyboard:  @keyboard
      show:      true
      backdrop:  @backdrop
      container: @container
    ).on(
      'show.bs.modal':   @localOnShow
      'shown.bs.modal':  @localOnShown
      'hide.bs.modal':   @localOnClose
      'hidden.bs.modal': @localOnClosed
      'dismiss.bs.modal': @localOnCancel
    )

    if @closeOnAnyClick
      @el.on('click', =>
        @close()
      )

  close: (e) =>
    if e
      e.preventDefault()
    @initalFormParamsIgnore = true
    @el.modal('hide')

  formParams: =>
    if @container
      return @formParam(@container.find('.modal form'))
    return @formParam(@$('.modal form'))

  localOnShow: (e) =>
    @onShow(e)

  onShow: (e) ->
    # do nothing

  localOnShown: (e) =>
    @onShown(e)

  onShown: (e) =>
    if @autoFocusOnFirstInput
      @$('input:not([disabled]):not([type="hidden"]):not(".btn"), textarea').first().focus()
    @initalFormParams = @formParams()

  localOnClose: (e) =>
    diff = difference(@initalFormParams, @formParams())
    if @initalFormParamsIgnore is false && !_.isEmpty(diff)
      if !confirm(App.i18n.translateContent('The form content has been changed. Do you want to close it and lose your changes?'))
        e.preventDefault()
        return
    @onClose(e)

  onClose: ->
    # do nothing

  localOnClosed: (e) =>
    @onClosed(e)
    @el.modal('remove')

  onClosed: (e) ->
    # do nothing

  localOnCancel: (e) =>
    @onCancel(e)

  onCancel: (e) ->
    # do nothing

  cancel: (e) =>
    @close(e)
    @onCancel(e)

  onSubmit: (e) ->
    # do nothing

  submit: (e) =>
    e.stopPropagation()
    e.preventDefault()
    @onSubmit(e)

class App.SessionMessage extends App.ControllerModal
  showTrySupport: true

  onCancel: (e) =>
    if @forceReload
      @windowReload(e)

  onClose: (e) =>
    if @forceReload
      @windowReload(e)

  onSubmit: (e) =>
    if @forceReload
      @windowReload(e)
    else
      @close()

class App.UpdateHeader extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = @genericObject.subscribe(@render)

  release: =>
    App[ @genericObject.constructor.className ].unsubscribe(@subscribeId)

  render: (genericObject) =>
    @el.find('.page-header h1').html(genericObject.displayName())


class App.UpdateTastbar extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = @genericObject.subscribe(@update)

  release: =>
    App[ @genericObject.constructor.className ].unsubscribe(@subscribeId)

  update: (genericObject) =>

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

class App.ControllerWidgetPermanent extends App.Controller
  constructor: (params) ->
    if params.el
      params.el.append('<div id="' + params.key + '"></div>')
      params.el = ("##{params.key}")

    super(params)

class App.ControllerWidgetOnDemand extends App.Controller
  constructor: (params) ->
    params.el = $("##{params.key}")
    super

  element: =>
    $("##{@key}")

  html: (raw) =>

    # check if parent exists
    if !$("##{@key}").get(0)
      $('#app').before("<div id=\"#{@key}\" class=\"#{@className}\"></div>")
    $("##{@key}").html raw
