class App.Notify extends Spine.Controller
  events:
    'click .alert': 'destroy'

  constructor: ->
    super

    App.Event.bind 'notify', (data) =>
      @render(data)

    App.Event.bind 'notify:removeall', =>
      @log 'notify:removeall', @
      @destroyAll()

    App.Event.bind 'notifyDesktop', (data) =>
      if !data['icon']
        data['icon'] = 'unknown'
      notify.createNotification( data.msg, data )

    # request desktop notification after login
    App.Event.bind 'auth', (data) ->
      if !_.isEmpty(data)
        notify.requestPermission()

    notify.config( pageVisibility: false )

  render: (data) ->
#    notify = App.view('notify')(data: data)
#    @append( notify )

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
#    $(e.target).parents('.alert').remove();

  destroyAll: ->
    $.noty.closeAll()
#    $(@el).find('.alert').remove();

App.Config.set( 'notify', App.Notify, 'Widgets' )
