class App.Notify extends App.ControllerWidgetPermanent
  events:
    'click .alert': 'destroy'

  constructor: ->
    super

    @bind 'notify', (data) =>
      @render(data)

    @bind 'notify:removeall', =>
      @log 'notify:removeall', @
      @destroyAll()

    @bind 'notifyDesktop', (data) =>
      if !data['icon']
        data['icon'] = 'unknown'
      notify.createNotification( data.msg, data )

    # request desktop notification after login
    @bind 'auth', (data) ->
      if !_.isEmpty(data)
        notify.requestPermission()

    notify.config( pageVisibility: false )

  render: (data) ->

    # map noty naming
    if data['type'] is 'info'
      data['type'] = 'information'
    if data['type'] is 'warning'
      data['type'] = 'alert'

    if data['removeAll']
      $.noty.closeAll()
    if data.link
      data.msg = '<a href="' + data.link + '">' + data.msg + '</a>'
    $('#notify').noty(
      {
        dismissQueue: true
        text:     data.msg
        layout:   'top'
        type:     data.type
        theme:    'noty_theme_twitter'
        animateOpen: {
          height: 'toggle'
          opacity: 0.85,
        },
        animateClose: {
          opacity: 0.25
        },
        speed:            450
        timeout:          data.timeout || 3800
        closeButton:      false
        closeOnSelfClick: true
        closeOnSelfOver:  false
      }
    )

  destroy: (e) ->
    e.preventDefault()

  destroyAll: ->
    $.noty.closeAll()

App.Config.set( 'notify', App.Notify, 'Widgets' )
