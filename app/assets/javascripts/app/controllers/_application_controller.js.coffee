class App.Controller extends Spine.Controller
  
  # add @title methode to set title
  title: (name) ->
#    $('html head title').html( Config.product_name + ' - ' + App.i18n.translateInline(name) )
    document.title = Config.product_name + ' - ' + App.i18n.translateInline(name)

  # add @notify methode to create notification
  notify: (data) ->
    Spine.trigger 'notify', data

  # add @navupdate methode to update navigation
  navupdate: (url) ->
    Spine.trigger 'navupdate', url

  scrollTo: ( x = 0, y = 0 ) ->
    a = ->
      console.log('scollTo', x, y )
      window.scrollTo( x, y )

    @delay( a, 0 )

  reBind: (name, callback) =>
    Spine.one name, (data) =>
      @log 'rebind', name, data
      callback(data)
      @reBind(name, callback)

  isRole: (name) ->
    return false if !window.Session.roles
    for role in window.Session.roles
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

  ###

    table = @table(
      header:   ['Host', 'User', 'Adapter', 'Active'],
      overview: ['host', 'user', 'adapter', 'active'],
      model:    App.Channel,
      objects:  data,
    )

    table = @table(
      overview_extended: [
        { name: 'number',                 link: true },
        { name: 'title',                  link: true },
        { name: 'customer',               class: 'user-data', data: { id: true } },
        { name: 'ticket_state',           translate: true },
        { name: 'ticket_priority',        translate: true },
        { name: 'group' },
        { name: 'owner',                  class: 'user-data', data: { id: true } },
        { name: 'created_at',             callback: @frontendTime },
        { name: 'last_contact',           callback: @frontendTime },
        { name: 'last_contact_agent',     callback: @frontendTime },
        { name: 'last_contact_customer',  callback: @frontendTime },
        { name: 'first_response',         callback: @frontendTime },
        { name: 'close_time',             callback: @frontendTime },
      ],
      model:    App.Ticket,
      objects:  tickets,
    )

  ###

  table: (data) ->
    overview   = data.overview || data.model.configure_overview || []
    attributes = data.attributes || data.model.configure_attributes || {}
    header     = data.header

    # define normal header
    if header
      header_new = []
      for key in header
        header_new.push {
          display: key
        }
      header = header_new
    else if !data.overview_extended
      header = []
      for row in overview
        if attributes
          for attribute in attributes
            if row is attribute.name
              header.push attribute
            else
              rowWithoutId = row + '_id'
              if rowWithoutId is attribute.name
                header.push  attribute

    dataTypesForCols = []
    for row in overview
      dataTypesForCols.push {
        name: row,
        link: true,
      }

    # extended table format
    if data.overview_extended
      @log 'ggggggg', data.overview_extended
      if !header
        @log 'ggggggg222', data.overview_extended
        header = []
        for row in data.overview_extended
          for attribute in attributes
            if row.name is attribute.name
              header.push attribute
            else
              rowWithoutId = row.name + '_id'
              if rowWithoutId is attribute.name
                header.push attribute

      dataTypesForCols = data.overview_extended

    # generate content data
    objects = _.clone( data.objects )
    for object in objects

      # check if info for each col. is already there
      for row in dataTypesForCols

        # execute callback on content
        if row.callback
          object[row.name] = row.callback( object[row.name] )

        # lookup relation
        if !object[row.name]
          rowWithoutId = row.name + '_id'
          for attribute in attributes
            if rowWithoutId is attribute.name
              if attribute.relation && App[attribute.relation]
                record = App.Collection.find( attribute.relation, object[rowWithoutId] )
                object[row.name] = record.name

    @log 'table', 'header', header, 'overview', dataTypesForCols, 'objects', objects
    table = App.view('generic/table')(
      header:   header,
      overview: dataTypesForCols,
      objects:  objects,
      checkbox: data.checkbox,
    )
#    @log 'ttt', $(table).find('span')
#    $(table).find('span').bind('click', ->
#      console.log('----------click---------')
#    )

    # convert to jquery object
    table = $(table)

    # enable checkbox bulk selection
    if data.checkbox
      table.delegate('[name="bulk_all"]', 'click', (e) ->
        if $(e.target).attr('checked')
          $(e.target).parents().find('[name="bulk"]').attr( 'checked', true );
        else
          $(e.target).parents().find('[name="bulk"]').attr( 'checked', false );
      )

    return table

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
  humanTime: (time) =>
    current = new Date()
    created = new Date(time)
    string = ''
    diff = ( current - created ) / 1000
    if diff >= 86400
      unit = Math.round( ( diff / 86400 ) )
#      if unit > 1
#        return unit + ' ' + App.i18n.translateContent('days')
#      else
#        return unit + ' ' + App.i18n.translateContent('day')
      string = unit + ' ' + App.i18n.translateInline('d')
    if diff >= 3600
      unit = Math.round( ( diff / 3600 ) % 24 )
#      if unit > 1
#        return unit + ' ' + App.i18n.translateContent('hours')
#      else
#        return unit + ' ' + App.i18n.translateContent('hour')
      if string isnt ''
        string = string + ' ' + unit + ' ' + App.i18n.translateInline('h')
        return string
      else
        string = unit + ' ' + App.i18n.translateInline('h')
    if diff <= 86400
      unit = Math.round( ( diff / 60 ) % 60 )
#      if unit > 1
#        return unit + ' ' + App.i18n.translateContent('minutes')
#      else
#        return unit + ' ' + App.i18n.translateContent('minute')
      if string isnt ''
        string = string + ' ' + unit + ' ' + App.i18n.translateInline('m')
        return string
      else
        string = unit + ' ' + App.i18n.translateInline('m')
    return string

  userInfo: (data) =>
    # start customer info controller
    new App.UserInfo(
      el:      data.el || $('#customer_info'),
      user_id: data.user_id,
    )

  authenticate: ->
    console.log 'authenticate', window.Session

    # return rtue if session exists
    return true if window.Session['id']

    # remember requested url
    window.Config['requested_url'] = window.location.hash

    # redirect to login  
    @navigate '#login'
    return false

  frontendTime: (timestamp) ->
    '<span class="humanTimeFromNow" data-time="' + timestamp + '">?</span>'

  frontendTimeUpdate: ->
    update = =>
      ui = @
      $('.humanTimeFromNow').each( ->
#        console.log('rewrite frontendTimeUpdate', this)
        timestamp = $(this).data('time')
        time = ui.humanTime( timestamp )
        $(this).attr( 'title', App.i18n.translateTimestamp(timestamp) )
        $(this).text( time )
      )
    @interval( update, 30000, 'frontendTimeUpdate' )

  clearInterval: (interval_id) =>
    # check global var
    if !@intervalID
      @intervalID = {}

    clearInterval( @intervalID[interval_id] ) if @intervalID[interval_id]

  interval: (callback, interval, interval_id) =>

    # check global var
    if !@intervalID
      @intervalID = {}

    callback()

    # auto save
    every = (ms, cb) -> setInterval cb, ms

    # clear auto save
    clearInterval( @intervalID[interval_id] ) if @intervalID[interval_id]

    # request new data
    @intervalID[interval_id] = every interval, () =>
      callback()

  userPopups: (position = 'right') ->

    # remove old popovers
    $('.popover-inner').parent().remove()

    # show user popup    
    $('.user-data').popover(
      delay: { show: 500, hide: 1200 },
#      placement: 'bottom',
      placement: position,
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
            if item.name isnt 'firstname' && item.name isnt 'lastname'
              if item.info #&& ( @user[item.name] || item.name isnt 'note' )
                data.push item

        # insert data
        App.view('user_info_small')(
          user: user,
          data: data,
        )
    )

  userTicketPopups: (data) ->

    # remove old popovers
    $('.popover-inner').parent().remove()

    # get data
    tickets = {}
    App.Com.ajax(
      type:  'GET',
      url:   '/api/ticket_customer',
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
      delay: { show: 500, hide: 5200 },
      placement: data.position,
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
    Spine.trigger( 'ws:send', JSON.stringify(data) )

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

  modalShow: (params) =>
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

  modalHide: (e) =>
    if e
      e.preventDefault()
    @el.modal('hide')

  submit: (e) =>
    e.preventDefault()
    @log 'You need to implement your own "submit" method!'

class App.ErrorModal extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('error')(
      message: @message
    )
    @modalShow(
      backdrop: false,
      keyboard: false,
    )
