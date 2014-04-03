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

  ticketTableAttributes: (attributes) =>
    all_attributes = [
      { name: 'number',                 type: 'link', title: 'title', dataType: 'edit' },
      { name: 'title',                  type: 'link', title: 'title', dataType: 'edit' },
      { name: 'customer',               class: 'user-popover', data: { id: true } },
      { name: 'ticket_state',           translate: true, title: true },
      { name: 'ticket_priority',        translate: true, title: true },
      { name: 'group',                  title: 'group' },
      { name: 'owner',                  class: 'user-popover', data: { id: true } },
      { name: 'created_at',             callback: @frontendTime },
      { name: 'last_contact',           callback: @frontendTime },
      { name: 'last_contact_agent',     callback: @frontendTime },
      { name: 'last_contact_customer',  callback: @frontendTime },
      { name: 'first_response',         callback: @frontendTime },
      { name: 'close_time',             callback: @frontendTime },
      { name: 'escalation_time',        callback: @frontendTime, subclass: 'escalation' },
      { name: 'article_count',          },
    ]
    shown_all_attributes = []
    for all_attribute in all_attributes
      for attribute in attributes
        if all_attribute['name'] is attribute
          shown_all_attributes.push all_attribute
          break
    return shown_all_attributes

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
    return size

  # human readable time
  humanTime: ( time, escalation ) =>
    current = new Date()
    created = new Date(time)
    string = ''
    diff = ( current - created ) / 1000
    escalated = ''
    if escalation
      if diff > 0
        escalated = '-'
      if diff >= 0
        style = "class=\"label label-danger\""
      else if diff > -60 * 60
        style = "class=\"label label-warning\""
      else
        style = "class=\"label label-success\""

    if diff.toString().match('-')
      diff = diff.toString().replace('-', '')
      diff = parseFloat(diff)

    if diff >= 86400
      unit = Math.floor( ( diff / 86400 ) )
#      if unit > 1
#        return unit + ' ' + App.i18n.translateContent('days')
#      else
#        return unit + ' ' + App.i18n.translateContent('day')
      string = unit + ' ' + App.i18n.translateInline('d')
    if diff >= 3600
      unit = Math.floor( ( diff / 3600 ) % 24 )
#      if unit > 1
#        return unit + ' ' + App.i18n.translateContent('hours')
#      else
#        return unit + ' ' + App.i18n.translateContent('hour')
      if string isnt ''
        string = string + ' ' + unit + ' ' + App.i18n.translateInline('h')
        if escalation
          string = "<span #{style}>#{escalated}#{string}</b>"
        return string
      else
        string = unit + ' ' + App.i18n.translateInline('h')
    if diff <= 86400
      unit = Math.floor( ( diff / 60 ) % 60 )
#      if unit > 1
#        return unit + ' ' + App.i18n.translateContent('minutes')
#      else
#        return unit + ' ' + App.i18n.translateContent('minute')
      if string isnt ''
        string = string + ' ' + unit + ' ' + App.i18n.translateInline('m')
        if escalation
          string = "<span #{style}>#{escalated}#{string}</b>"
        return string
      else
        string = unit + ' ' + App.i18n.translateInline('m')

    if escalation
      string = "<span #{style}>#{escalated}#{string}</b>"
    return string

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

    # return rtue if session exists
    return true if @Session.get( 'id' )

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
        $(this).attr( 'title', App.i18n.translateTimestamp(timestamp) )
        $(this).html( time )
      )
    App.Interval.set( update, 30000, 'frontendTimeUpdate', 'ui' )

  ticketPopups: (position = 'right') ->

    # remove old popovers
    $('.popover').remove()

    # show ticket popup
    ui = @
    @el.find('.ticket-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      delay:      { show: 500, hide: 1200 }
      placement:  position
      title: ->
        ticket_id = $(@).data('id')
        ticket = App.Ticket.retrieve( ticket_id )
        App.i18n.escape( ticket.title )
      content: ->
        ticket_id = $(@).data('id')
        ticket = App.Ticket.retrieve( ticket_id )
        ticket.humanTime = ui.humanTime(ticket.created_at)
        # insert data
        App.view('popover/ticket')(
          ticket: ticket,
        )
    )

  userPopups: (position = 'right') ->

    # remove old popovers
    $('.popover').remove()

    # open user in new task if user isn't customer
    if !@isRole('Customer')
      @el.find('.user-popover').bind('click', (e) =>
        user_id = $(e.target).data('id')
        @navigate "#user/zoom/#{user_id}"
        $('.popover').remove()
      );

    # show user popup
    @el.find('.user-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      delay:      { show: 500, hide: 1200 }
      placement:  position
      title: ->
        user_id = $(@).data('id')
        user = App.User.find( user_id )
        App.i18n.escape( user.displayName() ) 
      content: ->
        user_id = $(@).data('id')
        user = App.User.find( user_id )

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

  organizationPopups: (position = 'right') ->

    # remove old popovers
    $('.popover').remove()

    # show organization popup
    @el.find('.organization-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      delay:      { show: 500, hide: 1200 }
      placement:  position
      title: ->
        organization_id = $(@).data('id')
        organization = App.Organization.find( organization_id )
        App.i18n.escape( organization.name )
      content: ->
        organization_id = $(@).data('id')
        organization = App.Organization.find( organization_id )
        # insert data
        App.view('popover/organization')(
          organization: organization,
        )
    )

  userTicketPopups: (params) ->

    # remove old popovers
    $('.popover').remove()

    show = (data, tickets) =>

      if !data.position
        data.position = 'left'

      # show user popup
      controller = @
      @el.find(data.selector).popover(
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

  ws_send: (data) ->
    App.Event.trigger( 'ws:send', JSON.stringify(data) )

class App.ControllerPermanent extends App.Controller
  constructor: ->
    super
    $('#content_permanent').show()
    @el.find('#content').empty()

class App.ControllerContent extends App.Controller
  constructor: ->
    super
    $('#content_permanent').hide()

class App.ControllerModal extends App.Controller
  className: 'modal fade',
  tag: 'div',

  events:
    'submit form':   'submit',
    'click .submit': 'submit',
    'click .cancel': 'modalHide',
    'click .close':  'modalHide',

  constructor: (options) ->

    # do not use @el, because it's inserted by js
    if options
      delete options.el

      # callbacks
#      @callback = {}
#      if options.success
#        @callback.success = options.success
#      if options.error
#        @callback.error = options.error

    super(options)
    if options.show
      @render()

  render: ->
    @html App.view('modal')(
      title:   @title,
      message: @message
      detail:  @detail
      close:   @close
    )
    @modalShow(
      backdrop: @backdrop,
      keyboard: @keyboard,
    )

  modalShow: (params) ->
    defaults = {
      backdrop: true,
      keyboard: true,
      show: true,
    }
    data = $.extend({}, defaults, params)
    @el.modal(data)

    @el.bind('hidden.bs.modal', =>

      # navigate back to home page
#      if @pageData && @pageData.home
#        @navigate @pageData.home

      # navigate back
      if params && params.navigateBack
        window.history.back()

      # remove modal from dom
      $('.modal').remove();
    )

  modalHide: (e) ->
    if e
      e.preventDefault()
    @el.modal('hide')

  submit: (e) ->
    e.preventDefault()
    @log 'error', 'You need to implement your own "submit" method!'

class App.ErrorModal extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('modal')(
      title:   'Error',
      message: @message
      detail:  @detail
      close:   @close
    )
    @modalShow(
      backdrop: false,
      keyboard: false,
    )

class App.SessionMessage extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('modal')(
      title:   @title || '?'
      message: @message || '?'
      detail:  @detail
      close:   @close
      button:  @button
    )
    @modalShow(
      backdrop: @backdrop,
      keyboard: @keyboard,
    )

    # reload page on modal hidden
    if @forceReload
      @el.on('hidden', =>
        @reload()
      )

  modalHide: (e) =>
    if @forceReload
      @reload(e)
    @el.modal('hide')

  submit: (e) =>
    if @forceReload
      @reload(e)

  reload: (e) ->
    if e
      e.preventDefault()
    if window.location.reload
      window.location.reload()
      return true
    if window.location.href
      window.location.href = window.location.href
      return true

    throw "Cant reload page!"

