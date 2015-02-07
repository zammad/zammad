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
      size = Math.round( size / ( 1024 * 1024 ) ) + ' MB'
    else if size > 1024
      size = Math.round( size / 1024 ) + ' KB'
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

  authenticate: (checkOnly = false) ->

    # return true if session exists
    return true if @Session.get()

    # remember requested url
    @Config.set( 'requested_url', window.location.hash )

    return false if checkOnly

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

    # open ticket in new task if curent user agent
    if @isRole('Agent')
      @el.find('div.ticket-popover, span.ticket-popover').bind('click', (e) =>
        id = $(e.target).data('id')
        if id
          ticket = App.Ticket.find(id)
          @navigate ticket.uiUrl()
      );

    @ticketPopupsDestroy()

    # show ticket popup
    ui = @
    @ticketPopupsList = @el.find('.ticket-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      animation:  false
      delay:      100
      placement:  position
      title: ->
        ticket_id = $(@).data('id')
        ticket    = App.Ticket.fullLocal( ticket_id )
        App.Utils.htmlEscape( ticket.title )
      content: ->
        ticket_id        = $(@).data('id')
        ticket           = App.Ticket.fullLocal( ticket_id )
        ticket.humanTime = ui.humanTime(ticket.created_at)
        App.view('popover/ticket')(
          ticket: ticket
        )
    )

  ticketPopupsDestroy: =>
    if @ticketPopupsList
      @ticketPopupsList.popover('destroy')

  userPopups: (position = 'right') ->

    # open user in new task if current user is agent
    if @isRole('Agent')
      @el.find('div.user-popover, span.user-popover').bind('click', (e) =>
        id = $(e.target).data('id')
        if id
          user = App.User.find(id)
          @navigate user.uiUrl()
      );

    @userPopupsDestroy()

    # show user popup
    @userPopupsList = @el.find('.user-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      animation:  false
      delay:      100
      placement:  "auto #{position}"
      title: ->
        user_id = $(@).data('id')
        user    = App.User.fullLocal( user_id )
        App.Utils.htmlEscape( user.displayName() )
      content: ->
        user_id = $(@).data('id')
        user    = App.User.fullLocal( user_id )

        # get display data
        userData = []
        for attributeName, attributeConfig of App.User.attributesGet('view')

          # check if value for _id exists
          name    = attributeName
          nameNew = name.substr( 0, name.length - 3 )
          if nameNew of user
            name = nameNew

          # add to show if value exists
          if user[name] && attributeConfig.shown

            # do not show firstname and lastname / already show via diplayName()
            if name isnt 'firstname' && name isnt 'lastname' && name isnt 'organization'
              userData.push attributeConfig

        # insert data
        App.view('popover/user')(
          user:     user
          userData: userData
        )
    )

  userPopupsDestroy: =>
    if @userPopupsList
      @userPopupsList.popover('destroy')

  organizationPopups: (position = 'right') ->

    # open org in new task if current user agent
    if @isRole('Agent')
      @el.find('div.organization-popover, span.organization-popover').bind('click', (e) =>
        id = $(e.target).data('id')
        if id
          organization = App.Organization.find(id)
          @navigate organization.uiUrl()
      );

    @organizationPopupsDestroy()

    # show organization popup
    @organizationPopupsList = @el.find('.organization-popover').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      animation:  false
      delay:      100
      placement:  "auto #{position}"
      title: ->
        organization_id = $(@).data('id')
        organization    = App.Organization.fullLocal( organization_id )
        App.Utils.htmlEscape( organization.name )
      content: ->
        organization_id = $(@).data('id')
        organization    = App.Organization.fullLocal( organization_id )

        # get display data
        organizationData = []
        for attributeName, attributeConfig of App.Organization.attributesGet('view')

          # check if value for _id exists
          name    = attributeName
          nameNew = name.substr( 0, name.length - 3 )
          if nameNew of organization
            name = nameNew

          # add to show if value exists
          if organization[name] && attributeConfig.shown

            # do not show firstname and lastname / already show via diplayName()
            if name isnt 'name'
              organizationData.push attributeConfig

        # insert data
        App.view('popover/organization')(
          organization:     organization,
          organizationData: organizationData,
        )
    )

  organizationPopupsDestroy: =>
    if @organizationPopupsList
      @organizationPopupsList.popover('destroy')

  userTicketPopups: (params) ->

    show = (data, ticket_list) =>

      if !data.position
        data.position = 'left'

      @userTicketPopupsDestroy()

      # show user popup
      controller = @
      @userTicketPopupsList = @el.find(data.selector).popover(
        trigger:    'hover'
        container:  'body'
        html:       true
        animation:  false
        delay:      100
        placement:  "auto #{data.position}"
        title: ->
          $(@).find('[title="*"]').val()

        content: ->
          type = $(@).filter('[data-type]').data('type')
          tickets = []
          if ticket_list[type]
            for ticket_id in ticket_list[type]
              tickets.push App.Ticket.fullLocal( ticket_id )

          # insert data
          App.view('popover/user_ticket_list')(
            tickets: tickets,
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
          App.Store.write( "user-ticket-popover::#{params.user_id}",  data )

          # load assets
          App.Collection.loadAssets( data.assets )

          show( params, { open: data.ticket_ids_open, closed: data.ticket_ids_closed } )
      )

    # get data
    data = App.Store.get( "user-ticket-popover::#{params.user_id}" )
    if data
      show( params, { open: data.ticket_ids_open, closed: data.ticket_ids_closed } )
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

  # central method, is getting called on every ticket form change
  ticketFormChanges: (params, attribute, attributes, classname, form, ui) =>
    if @form_meta.dependencies && @form_meta.dependencies[attribute.name]
      dependency = @form_meta.dependencies[attribute.name][ parseInt(params[attribute.name]) ]
      if !dependency
        dependency = @form_meta.dependencies[attribute.name][ params[attribute.name] ]
      if dependency
        for fieldNameToChange of dependency
          filter = []
          if dependency[fieldNameToChange]
            filter = dependency[fieldNameToChange]

          # find element to replace
          for item in attributes
            if item.name is fieldNameToChange
              item['filter'] = {}
              item['filter'][ fieldNameToChange ] = filter
              item.default = params[item.name]
              #if !item.default
              #  delete item['default']
              newElement = ui.formGenItem( item, classname, form )

          # replace new option list
          form.find('[name="' + fieldNameToChange + '"]').closest('.form-group').replaceWith( newElement )

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
  elements:
    '.modal-body': 'body'

  events:
    'submit form':                        'onSubmit'
    'click .js-submit:not(.is-disabled)': 'onSubmit'
    'click .js-cancel':                   'hide'
    'click .js-close':                    'hide'

  className: 'modal fade'

  constructor: (options = {}) ->
    defaults =
      backdrop: true
      keyboard: true
      close:    true
      head:     '?'
      buttonClass: 'btn--success'
      centerButtons: []
      container: null

    options = _.extend( defaults, options )

    super(options)

    if @shown
      @show()

  show: (content) ->
    if @button is true
      @button = 'Submit'

    @html App.view('modal')
      head:          @head
      message:       @message
      detail:        @detail
      close:         @close
      cancel:        @cancel
      button:        @button
      buttonClass:   @buttonClass
      centerButtons: @centerButtons
      content:       content

    if @content
      @body.html @content

    if @container
      @el.addClass('modal--local')

    @el.modal
      keyboard:  @keyboard
      show:      true
      backdrop:  @backdrop
      container: @container
    .on
      'show.bs.modal':   @onShow
      'shown.bs.modal':  @onShown
      'hidden.bs.modal': =>
        @onHide()
        # remove modal from dom
        $('.modal').remove()

  hide: (e) =>
    if e
      e.preventDefault()
    @el.modal('hide')

  onShown: ->
    console.log('modal shown: do nothing')
    # do nothing

  onShow: ->
    console.log('modal rendered: do nothing')
    # do nothing

  onHide: ->
    console.log('modal removed: do nothing')
    # do nothing

  onSubmit: (e) =>
    e.preventDefault()
    @log 'error', 'You need to implement your own "onSubmit" method!'

class App.ErrorModal extends App.ControllerModal
  constructor: ->
    super
    @show()

class App.SessionMessage extends App.ControllerModal
  constructor: ->
    super
    @show(@content)

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
