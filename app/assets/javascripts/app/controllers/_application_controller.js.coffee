class App.Controller extends Spine.Controller
  @include App.LogInclude

  constructor: (params) ->

    # unbind old bindlings
    if params && params.el && params.el.unbind
      params.el.unbind()

    super

    # generate controllerId
    @controllerId = 'controller-' + new Date().getTime() + '-' + Math.floor( Math.random() * 999999 )

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

  delay: (callback, timeout, delay_id) =>
    App.Delay.set(callback, timeout, delay_id, @controllerId)

  clearInterval: (interval_id) =>
    App.Interval.clear(interval_id, @controllerId)

  interval: (callback, interval, interval_id) =>
    App.Interval.set(callback, interval, interval_id, @controllerId)

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

  release: =>
    # release custom bindings after it got removed from dom

  # add @title methode to set title
  title: (name) ->
#    $('html head title').html( @Config.get(product_name) + ' - ' + App.i18n.translateInline(name) )
    document.title = @Config.get('product_name') + ' - ' + App.i18n.translatePlain(name)

  copyToClipboard: (text) ->
    if window.clipboardData # IE
      window.clipboardData.setData( 'Text', text )
    else
      window.prompt( "Copy to clipboard: Ctrl+C, Enter", text )

  # disable all delay's and interval's
  disconnectClient: ->
    App.Delay.reset()
    App.Interval.reset()
    App.WebSocket.close( force: true )

  # add @notify methode to create notification
  notify: (data) ->
    App.Event.trigger 'notify', data

  # add @notifyDesktop methode to create desktop notification
  notifyDesktop: (data) ->
    App.Event.trigger 'notifyDesktop', data

  # add @navupdate methode to update navigation
  navupdate: (url) ->
    App.Event.trigger 'navupdate', url

  # show navigation
  navShow: ->
    return if $('#navigation').is(':visible')
    $('#navigation').removeClass('hide')

  # hide navigation
  navHide: ->
    return if !$('#navigation').is(':visible')
    $('#navigation').addClass('hide')

  scrollTo: ( x = 0, y = 0, delay = 0 ) ->
    a = ->
      window.scrollTo( x, y )

    @delay( a, delay )

  shake: (element) ->

    # this part is from wordpress 3, thanks to open source
    shakeMe = (element, position, positionEnd) ->
      positionStart = position.shift()
      element.css( 'left', positionStart + 'px' )
      if position.length > 0
        setTimeout( ->
            shakeMe( element, position, positionEnd )
        , positionEnd)
      else
        try
          element.css( 'position', 'static' )
        catch e

    position = [ 15, 30, 15, 0, -15, -30, -15, 0 ]
    position = position.concat( position.concat( position ) )
    element.css( 'position', 'relative' ) 
    shakeMe( element, position, 20 ) 

  isRole: (name) ->
    roles = @Session.get( 'roles' )
    return false if !roles
    for role in roles
      return true if role.name is name
    return false

  # get all params of the form
  formParam: (form) ->
    App.ControllerForm.params(form)

  formDisable: (form) ->
    App.ControllerForm.disable(form)

  formEnable: (form) ->
    App.ControllerForm.enable(form)

  formValidate: (data) ->
    App.ControllerForm.validate(data)

#  redirectToLogin: (data) ->
#

  # human readable file size
  humanFileSize: (size) =>
    if size > ( 1024 * 1024 )
      size = Math.round( size / ( 1024 * 1024 ) ) + ' MBytes'
    else if size > 1024
      size = Math.round( size / 1024 ) + ' KBytes'
    else
      size = size + ' Bytes'
    size

  # human readable time
  humanTime: ( time, escalation, long = true ) =>
    App.PrettyDate.humanTime( time, escalation, long )

  userInfo: (data) =>
    el = data.el || $('[data-id="customer_info"]')
    el.unbind()

    # start customer info controller
    new App.WidgetUser(
      el:       el
      user_id:  data.user_id
      callback: data.callback
    )

  authenticate: ->

    # return true if session exists
    return true if @Session.get()

    # remember requested url
    @Config.set( 'requested_url', window.location.hash )

    # redirect to login
    @navigate '#login'
    return false

  frontendTime: (timestamp, row = {}) ->
    if !row['subclass']
      row['subclass'] = ''
    "<span class=\"humanTimeFromNow #{row.subclass}\" data-time=\"#{timestamp}\">?</span>"

  frontendTimeUpdate: =>
    update = =>
      ui = @
      $('.humanTimeFromNow').each( ->
#        console.log('rewrite frontendTimeUpdate', this, $(this).hasClass('escalation'))
        timestamp = $(this).data('time')
        time = ui.humanTime( timestamp, $(this).hasClass('escalation') )
        $(this).attr( 'data-tooltip', App.i18n.translateTimestamp(timestamp) )
        $(this).html( time )
      )
    App.Interval.set( update, 30000, 'frontendTimeUpdate', 'ui' )

  ticketPopups: (position = 'right') ->

    @ticketPopupsDestroy()

    # show ticket popup
    ui = @
    @ticketPopupsList = @el.find('.ticket-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      delay:      { show: 400, hide: 400 }
      placement:  position
      title: ->
        ticket_id = $(@).data('id')
        ticket = App.Ticket.fullLocal( ticket_id )
        App.i18n.escape( ticket.title )
      content: ->
        ticket_id = $(@).data('id')
        ticket = App.Ticket.fullLocal( ticket_id )
        ticket.humanTime = ui.humanTime(ticket.created_at)
        # insert data
        App.view('popover/ticket')(
          ticket: ticket,
        )
    )

  ticketPopupsDestroy: =>
    if @ticketPopupsList
      @ticketPopupsList.popover('destroy')

  userPopups: (position = 'right') ->

    # open user in new task if user isn't customer
    if !@isRole('Customer')
      @el.find('.user-popover').bind('click', (e) =>
        user_id = $(e.target).data('id')
        @navigate "#user/zoom/#{user_id}"
      );

    @userPopupsDestroy()

    # show user popup
    @userPopupsList = @el.find('.user-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      delay:      { show: 400, hide: 400 }
      placement:  position
      title: ->
        user_id = $(@).data('id')
        user = App.User.fullLocal( user_id )
        App.i18n.escape( user.displayName() )
      content: ->
        user_id = $(@).data('id')
        user = App.User.fullLocal( user_id )

        # get display data
        data = []
        for item2 in App.User.configure_attributes
          item = _.clone( item2 )

          # check if value for _id exists
          itemNameValue = item.name
          itemNameValueNew = itemNameValue.substr( 0, itemNameValue.length - 3 )
          if itemNameValueNew of user
            item.name = itemNameValueNew

          # add to show if value exists
          if user[item.name]

            # do not show firstname and lastname / already show via diplayName()
            if item.name isnt 'firstname' && item.name isnt 'lastname' && item.name isnt 'organization'
              if item.info #&& ( @user[item.name] || item.name isnt 'note' )
                data.push item

        # insert data
        App.view('popover/user')(
          user: user,
          data: data,
        )
    )

  userPopupsDestroy: =>
    if @userPopupsList
      @userPopupsList.popover('destroy')

  organizationPopups: (position = 'right') ->

    @organizationPopupsDestroy()

    # show organization popup
    @organizationPopupsList = @el.find('.organization-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      delay:      { show: 400, hide: 400 }
      placement:  position
      title: ->
        organization_id = $(@).data('id')
        organization = App.Organization.fullLocal( organization_id )
        App.i18n.escape( organization.name )
      content: ->
        organization_id = $(@).data('id')
        organization = App.Organization.fullLocal( organization_id )
        # insert data
        App.view('popover/organization')(
          organization: organization,
        )
    )

  organizationPopupsDestroy: =>
    if @organizationPopupsList
      @organizationPopupsList.popover('destroy')

  userTicketPopups: (params) ->

    show = (data, tickets) =>

      if !data.position
        data.position = 'left'

      @userTicketPopupsDestroy()

      # show user popup
      controller = @
      @userTicketPopupsList = @el.find(data.selector).popover(
        trigger:    'hover'
        container:  'body'
        html:       true
        delay:      { show: 500, hide: 5200 }
        placement:  data.position
        title: ->
          $(@).find('[title="*"]').val()

        content: ->
          type = $(@).filter('[data-type]').data('type')
          data = tickets[type] || []

          # set human time
          for ticket in data
            ticket.humanTime = controller.humanTime(ticket.created_at)

          # insert data
          App.view('popover/user_ticket_list')(
            tickets: data,
          )
      )

    fetch = (params) =>
      @ajax(
        type:  'GET',
        url:   @Config.get('api_path') + '/ticket_customer',
        data:  {
          customer_id: params.user_id,
        }
        processData: true,
        success: (data, status, xhr) =>
          App.Store.write( "user-ticket-popover::#{params.user_id}",  data.tickets )
          show( params, data.tickets )
      )

    # get data
    tickets = App.Store.get( "user-ticket-popover::#{params.user_id}" )
    if tickets
      show( params, tickets )
      @delay(
        =>
          fetch(params)
        1000
        'fetch'
      )
    else
      fetch(params)

  userTicketPopupsDestroy: =>
    if @userTicketPopupsList
      @userTicketPopupsList.popover('destroy')

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

      item.link  = ''
      item.title = '???'

      # convert backend name space to local name space
      item.object = item.object.replace("::", '')

      # lookup real data
      if App[item.object] && App[item.object].exists( item.o_id )
        object            = App[item.object].find( item.o_id )
        item.link         = object.uiUrl()
        item.title        = object.displayName()
        item.object_name  = object.objectDisplayName()
        item.cssIcon      = object.iconActivity( @Session.get() )

      item.created_by = App.User.retrieve( item.created_by_id )
    items

  ws_send: (data) ->
    App.Event.trigger( 'ws:send', JSON.stringify(data) )

class App.ControllerPermanent extends App.Controller
  constructor: ->
    super
    $('.content').addClass('hide');
    @navShow()

class App.ControllerContent extends App.Controller
  constructor: ->
    super
    $('.content').addClass('hide');
    $('#content').removeClass('hide');
    @navShow()

class App.ControllerModal extends App.Controller
  constructor: (options = {}) ->
    defaults =
      backdrop: true
      keyboard: true
      close:    true
      head:     '?'
      buttonClass: 'btn--success'

    options = _.extend( defaults, options )

    # do not use @el, because it's inserted by js
    delete options.el

    super(options)

    if @shown
      @show()

  show: ->
    if @button is true
      @button = 'Submit'

    @modalElement = $( '<div class="modal fade"></div>' )
    @modalElement.append $( App.view('modal')(
      head:         @head
      message:      @message
      detail:       @detail
      close:        @close
      cancel:       @cancel
      button:       @button
      buttonClass:  @buttonClass
    ) )
    if @el && !@message && !@detail
      @modalElement.find('.modal-body').html @el

    @modalElement.find('form').on('submit', (e) => @onSubmit(e) )
    @modalElement.find('.js-submit').on('click', (e) => @onSubmit(e) )
    @modalElement.find('.js-cancel').on('click', (e) => @hide(e)  )
    @modalElement.find('.js-close').on('click', (e) => @hide(e) )

    @modalElement.modal(
      keyboard: @keyboard
      show:     true
      backdrop: @backdrop
    ).on('show.bs.modal', =>
      @onShow()
    ).on('hidden.bs.modal', =>
      @onHide()
      # remove modal from dom
      $('.modal').remove()
    ).find('.js-close').bind('submit', (e) => @hide(e) )

  hide: (e) ->
    if e
      e.preventDefault()
    @modalElement.modal('hide')

  onShow: ->
    console.log('no nothing')
    # do nothing

  onHide: ->
    console.log('no nothing')
    # do nothing

  onSubmit: (e) ->
    e.preventDefault()
    @log 'error', 'You need to implement your own "onSubmit" method!'

class App.ErrorModal extends App.ControllerModal
  constructor: ->
    super
    @show()

class App.SessionMessage extends App.ControllerModal
  constructor: ->
    super
    @show()

  # reload page on modal hidden
  onHide: (e) =>
    if @forceReload
      @reload(e)

  onSubmit: (e) =>
    if @forceReload
      @reload(e)

  reload: (e) ->
    if e
      e.preventDefault()
    $('#app').hide().attr('style', 'display: none!important')
    if window.location.reload
      window.location.reload()
      return true
    if window.location.href
      window.location.href = window.location.href
      return true

    throw "Cant reload page!"

class App.UpdateHeader extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = @genericObject.subscribe( @render )

  release: =>
    App[ @genericObject.constructor.className ].unsubscribe(@subscribeId)

  render: (genericObject) =>
    @el.find( '.page-header h1' ).html( genericObject.displayName() )


class App.UpdateTastbar extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = @genericObject.subscribe( @update )

  release: =>
    App[ @genericObject.constructor.className ].unsubscribe(@subscribeId)

  update: (genericObject) =>

    # update taskbar with new meta data
    App.Event.trigger 'task:render'
