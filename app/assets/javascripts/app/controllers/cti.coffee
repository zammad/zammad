class App.CTI extends App.Controller
  constructor: ->
    super

    @meta =
      active: false

    preferences = @Session.get('preferences') || {}
    @meta.active = preferences.cti || false

    @load()

    App.Event.bind(
      'cti_event'
      (data) =>
        console.log('cti_event', data)
        if data.state is 'newCall'
          console.log('notify')
          @notify(data)
      'cti_event'
    )
    App.Event.bind(
      'cti_list_push'
      (data) =>
        @list = data
        @render()
      'cti_list_push'
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
    console.log(data)
    #return if !
    if data.state is 'newCall' && data.direction is 'in'
      App.Event.trigger 'notify', {
        type:    'notice'
        msg:     App.i18n.translateContent('Call from %s for %s', data.from, data.to)
        timeout: 2500
      }

  featureActive: =>
    return true
    if @Config.get('sipgate_integration')
      return true
    false

  render: ->
    if !@isRole('CTI')
      @renderScreenUnauthorized(objectName: 'CTI')
      return

    @html App.view('cti/index')(
      list: @list
    )

    @updateNavMenu()

  show: (params) =>
    @title 'CTI', true
    @navupdate '#cti'

  counter: ->
    counter = 0

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
