class App.CTI extends App.Controller
  events:
    'click .js-check': 'done'

  constructor: ->
    super

    return if !@isRole('CTI')

    @list = []
    @meta =
      active: false
      counter: 0
      state: {}

    preferences = @Session.get('preferences') || {}
    @meta.active = preferences.cti || false

    @load()

    App.Event.bind(
      'cti_event'
      (data) =>
        console.log('cti_event', data)
        if data.direction is 'in'
          if data.state is 'newCall'
            if @switch()
              @notify(data)
            return if @meta.state[data.id]
            @meta.state[data.id] = true
            @meta.counter += 1
            @updateNavMenu()
          if data.state is 'answer' || data.state is 'hangup'
            return if !@meta.state[data.id]
            delete @meta.state[data.id]
            @meta.counter -= 1
            @updateNavMenu()

      'cti_event'
    )
    App.Event.bind(
      'cti_list_push'
      (data) =>
        @list = data
        @render()
      'cti_list_push'
    )
    App.Event.bind(
      'auth'
      (data) =>
        @meta.counter = 0
    )

    # rerender view, e. g. on langauge change
    @bind('ui:rerender', =>
      @render()
      'cti_rerender'
    )

  # fetch data, render view
  load: ->
    @ajax(
      id:    'cti_log'
      type:  'GET'
      url:   "#{@apiPath}/cti/log"
      success: (data) =>
        @list = data
        @render()
    )

  notify: (data) ->
    text = App.i18n.translateContent('Call from %s for %s', data.from_comment || data.from, data.to_comment || data.to)
    title = App.Utils.html2text(text.replace(/<.+?>/g, '"'))
    @notifyDesktop(
      url: '#cti'
      title: title
    )
    App.OnlineNotification.play()

  featureActive: =>
    return true
    return true if @Config.get('sipgate_integration')
    false

  render: ->
    if !@isRole('CTI')
      @renderScreenUnauthorized(objectName: 'CTI')
      return

    format = (time) ->
      # Minutes and seconds
      mins = ~~(time / 60)
      secs = time % 60

      # Hours, minutes and seconds
      hrs = ~~(time / 3600)
      mins = ~~((time % 3600) / 60)
      secs = time % 60

      # Output like "1:01" or "4:03:59" or "123:03:59"
      mins = "0#{mins}" if mins < 10
      secs = "0#{secs}" if secs < 10
      if hrs > 0
        return "#{hrs}:#{mins}:#{secs}"
      "#{mins}:#{secs}"

    for item in @list
      if item.state is 'newCall'
        item.state_human = 'ringing'
      else if item.state is 'answer'
        item.state_human = 'connected'
      else if item.state is 'hangup'
        if item.comment is 'cancel'
          item.state_human = 'not reached'
        else if item.comment is 'noAnswer'
          item.state_human = 'not reached'
        else if item.comment is 'congestion'
          item.state_human = 'not reached'
        else if item.comment is 'busy'
          item.state_human = 'busy'
        else if item.comment is 'notFound'
          item.state_human = 'not exist'
        else if item.comment is 'normalClearing'
          item.state_human = ''
        else
          item.state_human = item.comment
      else
        item.state_human = item.state
        if item.comment
          item.state_human += ", #{item.comment}"

      if item.start && item.end
        item.duration = format((Date.parse(item.end) - Date.parse(item.start))/1000)
    @html App.view('cti/index')(
      list: @list
    )

    @updateNavMenu()

  done: (e) =>
    element = $(e.currentTarget)
    id = element.closest('tr').data('id')
    done = element.prop('checked')
    @ajax(
      type:  'POST'
      url:   "#{@apiPath}/cti/done/#{id}"
      data:  JSON.stringify(done: done)
    )

  show: (params) =>
    @title 'CTI', true
    @navupdate '#cti'

  counter: =>
    count = 0
    for item in @list
      if item.state is 'hangup' && !item.done
        count++
    @meta.counter + count

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
      data:        JSON.stringify(user: {cti: state})
      processData: true
    )

  updateNavMenu: =>
    delay = ->
      App.Event.trigger('menu:render')
    @delay(delay, 200, 'updateNavMenu')

class CTIRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate(false, 'CTI')

    App.TaskManager.execute(
      key:        'CTI'
      controller: 'CTI'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set('cti', CTIRouter, 'Routes')
App.Config.set('CTI', { controller: 'CTI', authentication: true }, 'permanentTask')
App.Config.set('CTI', { prio: 1300, parent: '', name: 'Phone', target: '#cti', key: 'CTI', shown: false, role: ['CTI'], class: 'phone' }, 'NavBar')
