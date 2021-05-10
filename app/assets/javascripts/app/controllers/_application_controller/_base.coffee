class App.Controller extends Spine.Controller
  @include App.LogInclude
  @include App.RenderScreen

  constructor: ->
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

  navigate: (location, params = {}) ->
    @log 'debug', "navigate to '#{location}'"
    @log 'debug', "navigate hide from history '#{params.hideCurrentLocationFromHistory}'" if params.hideCurrentLocationFromHistory
    @el.empty() if params.emptyEl
    @el.remove() if params.removeEl

    # hide current location from browser history, allow to use back button in browser
    if params.hideCurrentLocationFromHistory
      if window.history
        history = App.Config.get('History')
        oldLocation = history[history.length-2]
        if oldLocation
          window.history.replaceState(null, null, oldLocation)
    super location

  preventDefault: (e) ->
    e.preventDefault()

  controllerBind: (event, callback) =>
    App.Event.bind(
      event
      callback
      @controllerId
    )

  controllerUnbind: (event, callback) =>
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
    @abortAjaxCalls()

    # release bindings
    if @el
      @el.undelegate()
      @el.unbind()
      @el.empty()

    # release spine bindings (see release() of spine.coffee)
    @off()
    @unbind()
    @stopListening()

  release: ->
    # nothing

  abortAjaxCalls: =>
    if !@ajaxCalls
      return

    idsToCancel = @ajaxCalls

    @ajaxCalls = []

    for callId in idsToCancel
      App.Ajax.abort(callId)

  # add @title method to set title
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

  # add @notify method to create notification
  notify: (data) ->
    App.Event.trigger('notify', data)

  # add @notifyDesktop method to create desktop notification
  notifyDesktop: (data) ->
    App.Event.trigger('notifyDesktop', data)

  # add @navupdate method to update navigation
  navupdate: (url, force = false) ->

    # ignore navupdate until #clues are gone
    return if !force && window.location.hash is '#clues'

    App.Event.trigger('navupdate', url)

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

  formDisable: (form, type) ->
    App.ControllerForm.disable(form, type)

  formEnable: (form, type) ->
    App.ControllerForm.enable(form, type)

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
    @requestedUrlToStore()

    if closeTab
      App.TaskManager.remove(@taskKey)

    # redirect to login
    @navigate '#login'

    throw "No permission for #{key}"

    false

  permissionCheck: (key) ->
    App.User.current()?.permission(key)

  authenticateCheckRedirect: ->
    return true if @authenticateCheck()

    # remember requested url
    @requestedUrlToStore()

    # redirect to login
    @navigate '#login'

    throw 'No exsisting session'

    false

  authenticateCheck: ->
    # return true if session exists
    return true if @Session.get()
    false

  requestedUrlToStore: ->
    location = window.location.hash

    return if !location
    return if location is '#'
    return if location is '#login'
    return if location is '#logout'
    return if location is '#session_timeout'
    return if location is '#keyboard_shortcuts'

    # remember requested url
    @requestedUrlRemember(location)

  requestedUrlRemember: (location) ->
    App.SessionStorage.set('requested_url', location) # for authentication agains third party
    App.Config.set('requested_url', location) # for local re-login

  requestedUrlWas: ->
    App.SessionStorage.get('requested_url') || App.Config.get('requested_url')

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
    timestamp = item.attr('datetime')
    time      = @humanTime(timestamp, item.hasClass('escalation'))

    # only do dom updates on changes
    return if time is currentVal
    item.attr('title', App.i18n.translateTimestamp(timestamp))
    item.html(time)

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

  preventDefaultAndStopPropagation: (e) ->
    e.preventDefault()
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
