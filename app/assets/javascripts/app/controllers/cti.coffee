class App.CTI extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  elements:
    '.js-callerLog': 'callerLog'
  events:
    'click .js-check':    'done'
    'click .js-checkAll': 'doneAll'
    'click .js-newUser':  'newUser'
  list: []
  backends: []
  meta:
    active: false
    counter: 0
    state: {}
  backendEnabled: false

  constructor: ->
    super

    preferences = @Session.get('preferences') || {}
    @meta.active = preferences.cti || false

    @load()
    @controllerBind('cti_list_push', (data) =>
      delay = =>
        @load()
      @delay(delay, 500, 'cti_list_push_render')
      'cti_list_push'
    )
    @controllerBind('cti_event', (data) =>
      return if data.state isnt 'newCall'
      return if data.direction isnt 'in'
      return if @switch() isnt true
      if !document.hasFocus()
        @notify(data)
      'cti_event'
    )
    @controllerBind('menu:render', (data) =>
      return if @switch() isnt true
      localHtml = App.view('navigation/menu_cti_ringing')(
        item: @ringingCalls()
      )
      $('.js-phoneMenuItem').after(localHtml)
      $('.call-widget').find('.js-newUser').bind('click', (e) =>
        @newUser(e)
      )
      $('.call-widget').find('.js-newTicket').bind('click', (e) =>
        user = undefined
        user_id = $(e.currentTarget).data('user-id')
        if user_id
          user = App.User.find(user_id)
        @newTicket(user)
      )
    )
    @controllerBind('auth', (data) =>
      @meta.counter = 0
    )
    @controllerBind('cti:reload', =>
      @load()
      'cti_reload'
    )

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender', =>
      @render()
      'cti_rerender'
    )

    # after a new websocket connection, load again
    @controllerBind('spool:sent', =>
      if @initSpoolSent
        @load()
        return
      @initSpoolSent = true
    )

  ringingCalls: =>
    ringing = []
    for row in @list
      if row.state is 'newCall' && row.done is false
        ringing.push row
    ringing

  # fetch data, render view
  load: ->
    @ajax(
      id:    'cti_log'
      type:  'GET'
      url:   "#{@apiPath}/cti/log"
      success: (data) =>
        if data.assets
          App.Collection.loadAssets(data.assets)
        if data.backends
          @backends = data.backends

          # check if configured backends are changed
          backendEnabled = false
          for backend in @backends
            if backend.enabled
              backendEnabled = true
          if backendEnabled isnt @backendEnabled
            @renderDone = false
          @backendEnabled = backendEnabled

        # render new caller list
        if data.list
          @list = data.list
          @updateNavMenu()
          if @renderDone
            @renderCallerLog()
            return
          @render()
    )

  notify: (data) ->
    text = App.i18n.translateContent('Call from %s for %s', data.from_comment || data.from, data.to_comment || data.to)
    title = App.Utils.html2text(text.replace(/<.+?>/g, '"'))
    @notifyDesktop(
      url: '#cti'
      title: title
    )

  featureActive: =>
    return true if @Config.get('sipgate_integration')
    return true if @Config.get('cti_integration')
    return true if @Config.get('placetel_integration')
    false

  render: ->
    @renderDone = true
    if !@permissionCheck('cti.agent')
      @renderScreenUnauthorized(objectName: 'CTI')
      return

    # check if min one backend is enabled
    if !@backendEnabled
      @html App.view('cti/not_configured')(
        backends: @backends
        isAdmin: @permissionCheck('admin.integration')
      )
      @updateNavMenu()
      return

    @html App.view('cti/index')()
    @renderCallerLog()

  renderCallerLog: ->
    for item in @list
      item.status_class = ''
      item.disabled = true
      if item.state is 'newCall'
        item.state_human = 'ringing'
        item.status_class = 'neutral'
      else if item.state is 'answer'
        item.state_human = 'connected'
        item.status_class = 'ok'
      else if item.state is 'hangup'
        item.disabled = false
        item.state_human = switch item.comment
          when 'cancel', 'noAnswer', 'congestion' then 'not reached'
          when 'busy' then 'busy'
          when 'notFound' then 'not exist'
          when 'normalClearing' then ''
          else item.comment
      else
        item.state_human = item.state
        if item.comment
          item.state_human += ", #{item.comment}"

      diff_in_min = ((Date.now() - Date.parse(item.created_at)) / 1000) / 60
      if diff_in_min > 1
        item.disabled = false

    @removePopovers()

    list = $(App.view('cti/caller_log')(list: @list))
    list.find('.js-avatar').each( ->
      $element = $(@)
      new WidgetAvatar(
        el:        $element
        object_id: $element.attr('data-id')
        level:     $element.attr('data-level')
        size:      40
      )
    )
    @callerLog.html(list)

    @updateNavMenu()

  doneAll: =>

    # get id's of all unchecked caller logs
    @logIds = $('.js-callerLog').map(->
      return $(@).data('id') if !$(@).find('.js-check').prop('checked')
    ).get()

    @ajax(
      type: 'POST'
      url:  "#{@apiPath}/cti/done/bulk"
      data: JSON.stringify({ids: @logIds})
    )

  done: (e) =>
    element = $(e.currentTarget)
    id      = element.closest('tr').data('id')
    done    = element.prop('checked')
    @ajax(
      type:  'POST'
      url:   "#{@apiPath}/cti/done/#{id}"
      data:  JSON.stringify(done: done)
      queue: 'cti_done_queue'
    )

  newTicket: (user) =>
    if user
      @navigate("ticket/create/customer/#{user.id}")
      return
    @navigate('ticket/create')

  newUser: (e) ->
    e.preventDefault()
    phone = $(e.currentTarget).data('phone')
    new App.ControllerGenericNew(
      pageData:
        title:     'Users'
        home:      'users'
        object:    'User'
        objects:   'Users'
        navupdate: '#users'
      genericObject: 'User'
      item:
        phone: phone
      #container: @el.closest('.content')
      callback: @ticketNew
    )

  ticketNew: (customer) ->
    @navigate "#ticket/create/customer/#{customer.id}"

  show: (params) =>
    @title 'CTI', true
    @navupdate '#cti'

  active: (state) =>
    return @shown if state is undefined
    @shown = state

  counter: =>
    count = 0
    for item in @list
      if !item.done
        count++
    @meta.counter = count

  switch: (state = undefined) =>

    # read state
    if state is undefined
      return @meta.active

    @meta.active = state

    # update user preferences
    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify(cti: state)
      processData: true
    )

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    @$('.main').scrollTop()

class WidgetAvatar extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  model: 'User'
  observe:
    login: true
    firstname: true
    lastname: true
    organization_id: true
    email: true
    image: true
    vip: true
    out_of_office: true,
    out_of_office_start_at: true,
    out_of_office_end_at: true,
    out_of_office_replacement_id: true,
    active: true

  globalRerender: false

  render: (user) =>
    classes = ['user-popover', 'u-textTruncate']
    classes.push('is-inactive') if !user.active
    @html(App.view('cti/caller_log_avatar')(user: user, classes: classes, level: @level))
    @renderPopovers()

class CTIRouter extends App.ControllerPermanent
  requiredPermission: 'cti.agent'
  constructor: (params) ->
    super

    App.TaskManager.execute(
      key:        'CTI'
      controller: 'CTI'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set('cti', CTIRouter, 'Routes')
App.Config.set('CTI', { controller: 'CTI', permission: ['cti.agent'] }, 'permanentTask')
App.Config.set('CTI', { prio: 1300, parent: '', name: 'Phone', target: '#cti', key: 'CTI', shown: false, permission: ['cti.agent'], class: 'phone' }, 'NavBar')
