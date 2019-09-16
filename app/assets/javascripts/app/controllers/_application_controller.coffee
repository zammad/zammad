class App.Controller extends Spine.Controller
  @include App.LogInclude
  @include App.RenderScreen

  constructor: (params) ->

    # unbind old bindings
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

  one: (event, callback) =>
    App.Event.bind(
      event
      callback
      @controllerId
      true
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
    @abortAjaxCalls()

  abortAjaxCalls: =>
    if !@ajaxCalls
      return

    idsToCancel = @ajaxCalls

    @ajaxCalls = []

    for callId in idsToCancel
      App.Ajax.abort(callId)

  # release Spine's event handling
  release: ->
    @off()
    @stopListening()

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
    App.Event.trigger 'notify', data

  # add @notifyDesktop method to create desktop notification
  notifyDesktop: (data) ->
    App.Event.trigger 'notifyDesktop', data

  # add @navupdate method to update navigation
  navupdate: (url, force = false) ->

    # ignore navupdate until #clues are gone
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
    App.User.current()?.permission(key)

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
    if @genericController && @genericController.show
      @genericController.show()
    return if !@header
    @title @header, true

  hide: =>
    if @genericController && @genericController.hide
      @genericController.hide()

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
  includeForm: true
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
      includeForm:       @includeForm
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

    @el
      .on(
        'show.bs.modal':   @localOnShow
        'shown.bs.modal':  @localOnShown
        'hide.bs.modal':   @localOnClose
        'hidden.bs.modal': @localOnClosed
        'dismiss.bs.modal': @localOnCancel
      ).modal(
        keyboard:  @keyboard
        show:      true
        backdrop:  @backdrop
        container: @container
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

  showAlert: (message, suffix = 'danger') ->
    alert = $('<div>')
      .addClass("alert alert--#{suffix}")
      .text(message)

    @$('.modal-alerts-container').html(alert)

  clearAlerts: ->
    @$('.modal-alerts-container').empty()

  localOnShow: (e) =>
    @onShow(e)

  onShow: (e) ->
    # do nothing

  localOnShown: (e) =>
    @onShown(e)

  onShown: (e) =>
    if @autoFocusOnFirstInput
      @$('input:not([disabled]):not([type="hidden"]):not(".btn"):not([type="radio"]:not(:checked)), textarea').first().focus()
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
    @clearAlerts()
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
