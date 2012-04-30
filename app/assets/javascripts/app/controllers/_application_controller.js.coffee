class App.Controller extends Spine.Controller
  
  # add @title methode to set title
  title: (name) ->
    $('html head title').html( Config.product_name + ' - ' + T(name) )

  # add @notify methode to create notification
  notify: (data) ->
    Spine.trigger 'notify', data

  # add @navupdate methode to update navigation
  navupdate: (url) ->
    Spine.trigger 'navupdate', url

  scrollTo: ( x = 0, y = 0 ) ->
    a = ->
      window.scrollTo( 0,0 )

    @delay( a, 0 )

#  # extend delegateEvents to unbind and undelegate
#  delegateEvents: ->
#    
#    # here unbind and undelegate while @el
#    @el.unbind()
#    @el.undelegate()
#    
#    for key, method of @events
#      unless typeof(method) is 'function'
#        method = @proxy(@[method])
#
#      match      = key.match(@eventSplitter)
#      eventName  = match[1]
#      selector   = match[2]
#
#      if selector is ''
#        @el.bind(eventName, method)
#      else
#        @el.delegate(selector, eventName, method)

  formGen: (data) ->
    form = $('<form>')
    fieldset = $('<fieldset>')
    fieldset.appendTo(form)
    autofocus = 1;
    if data.autofocus isnt undefined
      autofocus = data.autofocus

    attributes = clone( data.model.configure_attributes || [] )
    for attribute in attributes

      if !attribute.readonly && ( !data.required || data.required && attribute[data.required] )
  
        # set autofocus
        if autofocus is 1
          attribute.autofocus = 'autofocus'
          autofocus = 0
          
        # set required option
        if !attribute.null
          attribute.required = 'required'
        else
          attribute.required = ''

        # set multible option
        if attribute.multiple
          attribute.multiple = 'multiple'
        else
          attribute.multiple = ''
  
        # set autocapitalize option
        if attribute.autocapitalize is undefined || attribute.autocapitalize
          attribute.autocapitalize = ''
        else
          attribute.autocapitalize = 'autocapitalize="off"'
  
        # set value
        if data.params
          if attribute.name of data.params
            attribute.value = data.params[attribute.name]
            
        # set default value
        else
          if 'default' of attribute
#            @log 'default', attribute.default
            attribute.value = attribute.default
          else
            attribute.value = ''
        
        # add item
        item = $( @formGenItem(attribute, data.model.className) )
        item.appendTo(fieldset)
        
        # if password, add confirm password item
        if attribute.type is 'password'
          
          attribute.display = attribute.display + ' (confirm)'
          attribute.name = attribute.name + '_confirm';
  
          item = $( @formGenItem(attribute, data.model.className) )
          item.appendTo(fieldset)

    # return form
    return form.html()
    
  formGenItem: (attribute, classname) ->
    
    # create item id
    attribute.id = classname + '_' + attribute.name        

    # build options list based on config
    selection = []
    if attribute.options
      if attribute.nulloption
        attribute.options[''] = '-'
      for key of attribute.options
        selection.push {
          name:  attribute.options[key],
          value: key,
        }

    # build options list based on relation
    attribute.options = selection || []
    if attribute.relation && App[attribute.relation]
      attribute.options = []
      if attribute.nulloption
        attribute.options[''] = '-'
        attribute.options.push {
          name:  '-',
          value: '',
        }

      list = []
      if attribute.filter && attribute.filter[attribute.name]
        filter = attribute.filter[attribute.name]

        # check all records
        for record in App[attribute.relation].all()

          # check all filter attributes
          for key of filter

            # check all filter values as array
            for value in filter[key]
              
              # if it's matching, use it for selection
              if record[key] is value
                list.push record
      else
        list = App[attribute.relation].all()

      # build options list
      list.forEach( (item) =>
        
        # if active or if active doesn't exist
        if item.active || !( 'active' of item )
          name = '???'
          if item.name
            name = item.name
          else if item.firstname
            name = item.firstname
            if item.lastname
              if name
               name = name + ' '
            name = name + item.lastname

          name_new = name
          if attribute.translate
            name_new = T(name)
          attribute.options.push {
            name:  name_new,
            value: item.id,
            note:  item.note,
          }
      )

    # finde selected/checked item of list
    if attribute.options
      for record in attribute.options
        if typeof attribute.value is 'string' || typeof attribute.value is 'number' || typeof attribute.value is 'boolean'
          
          # if name or value is matching
          if record.value.toString() is attribute.value.toString() || record.name.toString() is attribute.value.toString()
            record.selected = 'selected'
            record.checked = 'checked'
#          if record.name.toString() is attribute.value.toString()
#            record.selected = 'selected'
#            record.checked = 'checked'
        if ( attribute.value && record.value && _.include(attribute.value, record.value) ) || ( attribute.value && record.name && _.include(attribute.value, record.name) )
          record.selected = 'selected'
          record.checked = 'checked'

    # boolean
    if attribute.tag is 'boolean'
      
      # build options list
      if _.isEmpty(attribute.options)
        attribute.options = [
          { name: 'active', value: true } 
          { name: 'inactive', value: false } 
        ]
      
      # update boolean types
      for record in attribute.options
        record.value = '{boolean}::' + record.value

      # finde selected item of list
      for record in attribute.options
        if record.value is '{boolean}::' + attribute.value
          record.selected = 'selected'
          
      # return item
      item = App.view('generic/select')( attribute: attribute )

    # select
    else if attribute.tag is 'select'
      item = App.view('generic/select')( attribute: attribute )

    # checkbox
    else if attribute.tag is 'checkbox'
      item = App.view('generic/checkbox')( attribute: attribute )
      
    # radio
    else if attribute.tag is 'radio'
      item = App.view('generic/radio')( attribute: attribute )
      
    # textarea
    else if attribute.tag is 'textarea'
      item = App.view('generic/textarea')( attribute: attribute )
      
    # autocompletion
    else if attribute.tag is 'autocompletion'
      item = App.view('generic/autocompletion')( attribute: attribute )
      
      a = ->
#        if attribute.relation && App[attribute.relation]
#          @log '1312312333333333333', App[attribute.relation]
#        @log '1231231231', '#' + attribute.id + '_autocompletion'
        @local_attribute = '#' + attribute.id
        @local_attribute_full = '#' + attribute.id + '_autocompletion'
        @callback = attribute.callback

        b = (event, key) =>
#          @log 'zzzz', event, item, key, @local_attribute
          $(@local_attribute).val(key)
          if @callback
            @callback( user_id: key )
        ###
        $(@local_attribute_full).tagsInput(
          autocomplete_url: '/user_search',
          height: '30px',
          width: '530px',
          auto: {
            source: '/user_search',
            minLength: 2,
            select: ( event, ui ) =>
              @log 'selected', event, ui
              b(event, ui.item.id)
          }
        )
        ###        
        $(@local_attribute_full).autocomplete(
          source: '/user_search',
          minLength: 2,
          select: ( event, ui ) =>
            @log 'selected', event, ui
            b(event, ui.item.id)
        )

      @delay(a, 800)

    # input
    else
      item = App.view('generic/input')( attribute: attribute )

    if !attribute.display
      return item
    else
      return App.view('generic/attribute')(
        attribute: attribute,
        item:      item,
      )

  # get all params of the form
  formParam: (form, errors) ->
    param = {}
    
    # find form based on sub elements
    if $(form).children()[0]
      form = $(form).children().parents('form')

    # find form based on parents next <form>
    else if $(form).parents('form')[0]
      form = $(form).parents('form')
        
    # find form based on parents next <form>, not really good!
    else if $(form).parents().find('form')[0]
      form = $(form).parents().find('form')
    else
      @log 'ERROR, no form found!', form
      
    for key in form.serializeArray()
      if param[key.name]
        if typeof param[key.name] is 'string'
          param[key.name] = [ param[key.name], key.value]
        else
          param[key.name].push key.value
      else

        # check boolean
        boolean = key.value.split '::'
        if boolean[0] is '{boolean}'
          if boolean[1] is 'true'
            key.value = true
          else
            key.value = false

        param[key.name] = key.value

    @log 'formParam', form, param
    return param

  formDisable: (form) ->
    @log 'disable...', $(form.target).parent()
    $(form.target).parent().find('[type="submit"]').attr('disabled', true)
    $(form.target).parent().find('[type="reset"]').attr('disabled', true)

  formEnable: (form) ->
    @log 'enable...', $(form).parent()
    $(form).parent().find('[type="submit"]').attr('disabled', false)
    $(form).parent().find('[type="reset"]').attr('disabled', false)

  table: (data) ->
    overview = data.overview || data.model.configure_overview || []
    attributes = data.attributes || data.model.configure_attributes || []

    # define normal header
    header = []
    for row in overview
      for attribute in attributes
        if row is attribute.name
          header.push(attribute.display)
        else
          rowWithoutId = row + '_id'
          if rowWithoutId is attribute.name
            header.push(attribute.display)

    data_types = []
    for row in overview
      data_types.push {
        name: row,
        link: 1,
      }

    # extended table format
    if data.overview_extended
      header = []
      for row in data.overview_extended
        for attribute in attributes
          if row.name is attribute.name
            header.push(attribute.display)
          else
            rowWithoutId = row.name + '_id'
            if rowWithoutId is attribute.name
              header.push(attribute.display)

      data_types = data.overview_extended

    # generate content data
    objects = clone( data.objects )
    for object in objects
      for row in data_types
        
        # check if data is a object
        if typeof object[row.name] is 'object'
          if !object[row.name]
            object[row.name] = {
              name: '-',
            }
            
          # if no content exists, try firstname/lastname
          if !object[row.name]['name']
            if object[row.name]['firstname'] || object[row.name]['lastname']
              object[row.name]['name'] = (object[row.name]['firstname'] || '') + ' ' + (object[row.name]['lastname'] || '')

        # if it isnt a object, create one
        else if typeof object[row.name] isnt 'object'
          object[row.name] = {
            name: object[row.name],
          }

        # fallback if it's something else
        else
          object[row.name] = {
            name: '????',
          }
          
        # execute callback on content
        if row.callback
          object[row.name]['name'] = row.callback(object[row.name]['name'])
 
#    @log 'table', 'header', header, 'overview', data_types, 'objects', objects
    table = App.view('generic/table')(
      header:   header,
      overview: data_types,
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
          $(e.target).parents().find('[name="bulk"]').attr('checked', true);
        else
          $(e.target).parents().find('[name="bulk"]').attr('checked', false);       
      )

    return table

  ticketTableAttributes: (attributes) =>
    all_attributes = [
      { name: 'number',                 link: true },
      { name: 'title',                  link: true },
      { name: 'customer',               class: 'user-data', data: { id: true } },
      { name: 'ticket_state' },
      { name: 'ticket_priority' },
      { name: 'group' },
      { name: 'owner',                  class: 'user-data', data: { id: true } },
      { name: 'created_at',             callback: @humanTime },
      { name: 'last_contact',           callback: @humanTime },
      { name: 'last_contact_agent',     callback: @humanTime },
      { name: 'last_contact_customer',  callback: @humanTime },
      { name: 'first_response',         callback: @humanTime },
      { name: 'close_time',             callback: @humanTime },
    ]
    shown_all_attributes = []
    for all_attribute in all_attributes
      for attribute in attributes
        if all_attribute['name'] is attribute
          shown_all_attributes.push all_attribute
          break
    return shown_all_attributes

  validateForm: (data) ->

    # remove all errors
    $(data.form).parents().find('.error').removeClass('error')
    $(data.form).parents().find('.help-inline').html('')

    # show new errors
    for key, msg of data.errors
      $(data.form).parents().find('[name*="' + key + '"]').parents('div .control-group').addClass('error')      
      $(data.form).parents().find('[name*="' + key + '"]').parent().find('.help-inline').html(msg);
    
    # set autofocus
    $(data.form).parents().find('.error').find('input, textarea').first().focus()

#    # enable form again
#    if $(data.form).parents().find('.error').html()
#      @formEnable(data.form)

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
    diff = (current - created) / 1000
    if diff >= 86400
      unit = Math.round( (diff / 86400) )
      if unit > 1
        return unit + ' days'
      else
        return unit + ' day'
    if diff >= 3600
      unit = Math.round( (diff / 3600) )
      if unit > 1
        return unit + ' hours'
      else
        return unit + ' hour'
    if diff <= 3600
      unit = Math.round( (diff / 60) )
      if unit > 1
        return unit + ' minutes'
      else
        return unit + ' minute'

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

  clone = (obj) ->
    if not obj? or typeof obj isnt 'object'
      return obj
  
    newInstance = new obj.constructor()
  
    for key of obj
      newInstance[key] = clone obj[key]
  
    return newInstance

  userPopups: (position = 'right') ->
    # show user popup    
    $('.user-data').popover(
      delay: { show: 500, hide: 1200 },
#      placement: 'bottom',
      placement: position,
      title: (e) =>
        user_id = $(e).data('id')
        user = App.User.find(user_id)
        (user.firstname || '') + ' ' +  (user.lastname || '')
      content: (e) =>
        user_id = $(e).data('id')
        user = App.User.find(user_id)

        # get display data
        data = []
        for item in App.User.configure_attributes
          if user[item.name]
            if item.name isnt 'firstname'
              if item.name isnt 'lastname'
                if item.info #&& ( @user[item.name] || item.name isnt 'note' )
                  data.push item

        # insert data
        App.view('user_info_small')(
          user: user,
          data: data,
        )    
    )

  userTicketPopups: (data) ->
    # get data
    @tickets = {}
    ajax = new App.Ajax
    ajax.ajax(
      type:  'GET',
      url:   '/ticket_customer',
      data:  {
        customer_id: data.user_id,
      }
      processData: true,
      success: (data, status, xhr) =>
        @tickets = data.tickets
    )

    if !data.position
      data.position = 'left'
      
    # show user popup    
    $(data.selector).popover(
      delay: { show: 500, hide: 5200 },
      placement: data.position,
      title: (e) =>
        $(e).find('[title="*"]').val()
        
      content: (e) =>
        type = $(e).filter('[data-type]').data('type')
        data = @tickets[type] || []

        for ticket in data
          
          # set human time
          ticket.humanTime = @humanTime(ticket.created_at)

        # insert data
        App.view('user_ticket_info_small')(
          tickets: data,
        )    
    )

  loadCollection: (params) ->
    
    # users
    if params.type == 'User'
      for user_id, user of params.data

        # set socal media links
        if user['accounts']
          for account of user['accounts']
            if account == 'twitter'
              user['accounts'][account]['link'] = 'http://twitter.com/' + user['accounts'][account]['username']
            if account == 'facebook'
              user['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + user['accounts'][account]['uid']

        # set image url
        if user && !user['image']
          user['image'] = 'http://placehold.it/48x48'
          
        # set realname
        user['realname'] = ''
        if user['firstname']
          user['realname'] = user['firstname']
        if user['lastname']
          if user['realname'] isnt ''
            user['realname'] = user['realname'] + ' '
          user['realname'] = user['realname'] + user['lastname']

        # load in collection if needed
        if !params.collection
          App.User.refresh( user, options: { clear: true } )

    # tickets
    else if params.type == 'Ticket'
      for ticket in params.data

        # set human time
        ticket.humanTime = @humanTime(ticket.created_at)

        # priority
        ticket.ticket_priority = App.TicketPriority.find(ticket.ticket_priority_id)
        
        # state
        ticket.ticket_state = App.TicketState.find(ticket.ticket_state_id)
        
        # group
        ticket.group = App.Group.find(ticket.group_id)
        
        # customer
        if ticket.customer_id and App.User.exists(ticket.customer_id)
          user = App.User.find(ticket.customer_id)
          ticket.customer = user
          
        # owner
        if ticket.owner_id and App.User.exists(ticket.owner_id)
          user = App.User.find(ticket.owner_id)
          ticket.owner = user

        # load in collection if needed
        if !params.collection
          App.Ticket.refresh( ticket, options: { clear: true } )

    # articles
    else if params.type == 'TicketArticle'
      for article in params.data
        
        # add user
        article.created_by = App.User.find(article.created_by_id)
        
        # set human time
        article.humanTime = @humanTime(article.created_at)
  
        # add possible actions
        article.article_type = App.TicketArticleType.find( article.ticket_article_type_id )
        article.article_sender = App.TicketArticleSender.find( article.ticket_article_sender_id )

        # load in collection if needed
        if !params.collection
          App.TicketArticle.refresh( article, options: { clear: true } )

    # history
    else if params.type == 'History'
      for histroy in params.data
        
        # add user
        histroy.created_by = App.User.find(histroy.created_by_id)
        
        # set human time
        histroy.humanTime = @humanTime(histroy.created_at)
  
        # add possible actions
        if histroy.history_attribute_id
          histroy.attribute = App.HistoryAttribute.find( histroy.history_attribute_id )
        if histroy.history_type_id
          histroy.type      = App.HistoryType.find( histroy.history_type_id )
        if histroy.history_object_id
          histroy.object    = App.HistoryObject.find( histroy.history_object_id )

        # load in collection if needed
        if !params.collection
          App.History.refresh( histroy, options: { clear: true } )

    # all the rest
    else
      for object in params.data

        # load in collection if needed
        if !params.collection
          App[params.type].refresh( object, options: { clear: true } )

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
    @el.modal({
      backdrop: true,
      keyboard: true,
      show: true
    })
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
