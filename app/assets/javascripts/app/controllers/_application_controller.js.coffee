class App.Controller extends Spine.Controller
  @include App.Log

  constructor: (params) ->

    # unbind old bindlings
    if params && params.el && params.el.unbind
      params.el.unbind()

    super

    # create shortcuts
    @Config  = App.Config
    @Session = App.Session

  # add @title methode to set title
  title: (name) ->
#    $('html head title').html( @Config.get(product_name) + ' - ' + App.i18n.translateInline(name) )
    document.title = @Config.get('product_name') + ' - ' + App.i18n.translatePlain(name)

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
      { name: 'number',                 link: true, title: 'title' },
      { name: 'title',                  link: true, title: 'title' },
      { name: 'customer',               class: 'user-data', data: { id: true } },
      { name: 'ticket_state',           translate: true, title: true },
      { name: 'ticket_priority',        translate: true, title: true },
      { name: 'group',                  title: 'group' },
      { name: 'owner',                  class: 'user-data', data: { id: true } },
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
        style = "class=\"label label-important\""
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
    new App.UserInfo(
      el:      el
      user_id: data.user_id
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
    @interval( update, 30000, 'frontendTimeUpdate' )


  clearDelay: (delay_id, level) =>
    App.Delay.clear(delay_id, level)

  delay: (callback, timeout, delay_id, level) =>
    App.Delay.set(callback, timeout, delay_id, level)

  clearInterval: (interval_id, level) =>
    App.Interval.clear(interval_id, level)

  interval: (callback, interval, interval_id, level) =>
    App.Interval.set(callback, interval, interval_id, level)

  ticketPopups: (position = 'right') ->

    # remove old popovers
    $('.popover-inner').parent().remove()

    # show ticket popup
    ui = @
    $('.ticket-data').popover(
      trigger: 'hover'
      html:    true
      delay:   { show: 500, hide: 1200 }
#      placement: 'bottom'
      placement: position
      title: ->
        ticket_id = $(@).data('id')
        ticket = App.Collection.find( 'Ticket', ticket_id )
        ticket.title
      content: ->
        ticket_id = $(@).data('id')
        ticket = App.Collection.find( 'Ticket', ticket_id )
        ticket.humanTime = ui.humanTime(ticket.created_at)
        # insert data
        App.view('ticket_info_small')(
          ticket: ticket,
        )
    )

  userPopups: (position = 'right') ->

    # remove old popovers
    $('.popover-inner').parent().remove()

    # show user popup
    $('.user-data').popover(
      trigger: 'hover'
      html:    true
      delay:   { show: 500, hide: 1200 }
#      placement: 'bottom'
      placement: position
      title: ->
        user_id = $(@).data('id')
        user = App.Collection.find( 'User', user_id )
        user.displayName()
      content: ->
        user_id = $(@).data('id')
        user = App.Collection.find( 'User', user_id )

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
        App.view('user_info_small')(
          user: user,
          data: data,
        )
    )

  organizationPopups: (position = 'right') ->

    # remove old popovers
    $('.popover-inner').parent().remove()

    # show organization popup
    $('.organization-data').popover(
      trigger: 'hover'
      html:    true
      delay:   { show: 500, hide: 1200 }
#      placement: 'bottom'
      placement: position
      title: ->
        organization_id = $(@).data('id')
        organization = App.Collection.find( 'Organization', organization_id )
        organization.name
      content: ->
        organization_id = $(@).data('id')
        organization = App.Collection.find( 'Organization', organization_id )
        # insert data
        App.view('organization_info_small')(
          organization: organization,
        )
    )

  userTicketPopups: (data) ->

    # remove old popovers
    $('.popover-inner').parent().remove()

    # get data
    tickets = {}
    App.Com.ajax(
      type:  'GET',
      url:   'api/ticket_customer',
      data:  {
        customer_id: data.user_id,
      }
      processData: true,
      success: (data, status, xhr) =>
        tickets = data.tickets
    )

    if !data.position
      data.position = 'left'

    # show user popup
    controller = @
    $(data.selector).popover(
      trigger: 'hover'
      html:    true
      delay:   { show: 500, hide: 5200 }
      placement: data.position
      title: ->
        $(@).find('[title="*"]').val()

      content: ->
        type = $(@).filter('[data-type]').data('type')
        data = tickets[type] || []

        # set human time
        for ticket in data
          ticket.humanTime = controller.humanTime(ticket.created_at)

        # insert data
        App.view('user_ticket_info_small')(
          tickets: data,
        )
    )

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
  className: 'modal hide fade',
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

    @el.bind('hidden', =>

      # navigate back to home page
      if @pageData && @pageData.home
        @navigate @pageData.home

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

class App.SessionReloadModal extends App.ControllerModal
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
    @el.on('hidden', =>
      @reload()
    )

  modalHide: (e) ->
    @reload(e)

  submit: (e) ->
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

