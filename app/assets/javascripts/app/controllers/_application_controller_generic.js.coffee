$.fn.item = (genericObject) ->
  elementID   = $(@).data('id')
  elementID or= $(@).parents('[data-id]').data('id')
  genericObject.find(elementID)

class App.ControllerGenericNew extends App.ControllerModal
  constructor: (params) ->
    super
    @render()

  render: ->

    @html App.view('generic/admin/new')( head: @pageData.object )
    new App.ControllerForm(
      el:         @el.find('#object_new'),
      model:      App[ @genericObject ],
      params:     @item,
      required:   @required,
      autofocus:  true,
    )
    @modalShow()

  submit: (e) ->
    e.preventDefault()
    params = @formParam( e.target )

    object = new App[ @genericObject ]
    object.load(params)

    # validate
    errors = object.validate()
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # disable form
    @formDisable(e)

    # save object
    ui = @
    object.save(
      success: ->
        if ui.callback
          item = App[ ui.genericObject ].retrieve(@id)
          ui.callback( item )
        ui.modalHide()

      error: ->
        ui.log 'errors'
        ui.modalHide()
    )

class App.ControllerGenericEdit extends App.ControllerModal
  constructor: (params) ->
    super
    @item = App[ @genericObject ].find( params.id )
    @render()

  render: ->

    @html App.view('generic/admin/edit')( head: @pageData.object )
    new App.ControllerForm(
      el:         @el.find('#object_edit')
      model:      App[ @genericObject ]
      params:     @item
      required:   @required
      autofocus:  true
    )
    @modalShow()

  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target) 
    @item.load(params)

    # validate
    errors = @item.validate()
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # disable form
    @formDisable(e)

    # save object
    ui = @
    @item.save(
      success: ->
        if ui.callback
          item = App[ ui.genericObject ].retrieve(@id)
          ui.callback( item )
        ui.modalHide()

      error: =>
        ui.log 'errors'
        ui.modalHide()
    )

class App.ControllerGenericIndex extends App.Controller
  events:
    'click [data-type=edit]':    'edit'
    'click [data-type=destroy]': 'destroy'
    'click [data-type=new]':     'new'

  constructor: ->
    super

    # set title
    @title @pageData.title

    # set nav bar
    @navupdate @pageData.navupdate

    # bind render after a change is done
    if !@disableRender
      @subscribeId = App[ @genericObject ].subscribe(@render)

    App[ @genericObject ].bind 'ajaxError', (rec, msg) =>
      @log 'error', 'ajax', msg.status
      if msg.status is 401
        @log 'error', 'ajax', rec, msg, msg.status
#        @navigate @pageData.navupdate
#        alert('relogin')
        @navigate 'login'

    # execute fetch
    @render()

    # fetch all
    if !@disableInitFetch
      App[ @genericObject ].fetch()

  release: =>
    if @subscribeId
      App[ @genericObject ].unsubscribe(@subscribeId)

  render: =>

    objects = App[@genericObject].search( sortBy: @defaultSortBy || 'name' )

    # remove ignored items from collection
    if @ignoreObjectIDs
      objects = _.filter( objects, (item) ->
        return if item.id is 1
        return item
      )

    @html App.view('generic/admin/index')(
      head:    @pageData.objects
      notes:   @pageData.notes
      buttons: @pageData.buttons
      menus:   @pageData.menus
    )

    # append additional col. link switch to
    overview = _.clone( App[ @genericObject ].configure_overview )
    attributes = _.clone( App[ @genericObject ].configure_attributes )
    if @pageData.addCol
      for item in @pageData.addCol.overview
        overview.push item
      for item in @pageData.addCol.attributes
        attributes.push item

    # append content table
    new App.ControllerTable(
      el:         @el.find('.table-overview')
      model:      App[ @genericObject ]
      objects:    objects
      overview:   overview
      attributes: attributes
    )

    binds = {}
    for item in attributes
      if item.dataType
        if !binds[item.dataType]
          callback = item.callback || @edit
          @el.on( 'click', "[data-type=#{item.dataType}]", callback )
          binds[item.dataType] = true

  edit: (e) =>
    e.preventDefault()
    item = $(e.target).item( App[ @genericObject ] )

    if @editCallback
      @editCallback(item)
      return

    new App.ControllerGenericEdit(
      id:            item.id
      pageData:      @pageData
      genericObject: @genericObject
    )

  destroy: (e) ->
    e.preventDefault()
    item = $(e.target).item( App[ @genericObject ] )
    new DestroyConfirm(
      item: item
    )

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:      @pageData
      genericObject: @genericObject
    )

class DestroyConfirm extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('modal')(
      title:   'Confirm'
      message: 'Sure to delete this object?'
      cancel:  true
      button:  'Yes'
    )
    @modalShow(
      backdrop: true
      keyboard: true
    )

  submit: (e) =>
    @modalHide()
    @item.destroy()

class App.ControllerDrox extends App.Controller
  constructor: (params) ->
    super

    if params.data && ( params.data.text || params.data.html )
      @inline(params.data)

  inline: (data) ->
    @html App.view('generic/drox')(data)
    if data.text
      @el.find('.drox-body').text(data.text)
    if data.html
      @el.find('.drox-body').html(data.html)

  template: (data) ->
    drox = $( App.view('generic/drox')(data) )
    content = App.view(data.file)(data.params)
    drox.find('.drox-body').append(content)
    drox

class App.ControllerLevel2 extends App.ControllerContent
  events:
    'click [data-toggle="tabnav"]': 'toggle',

  constructor: ->
    super

  render: ->

    # set title
    @title @page.title
    @navupdate @page.nav

    @html App.view('generic/admin_level2/index')(
      page:     @page
      menus:    @menu
      type:     @type
      target:   @target
    )

    if !@target
      @target = @menu[0]['target']

    for menu in @menu
      @el.find('.nav-tab-content').append('<div class="tabbable" id="' + menu.target + '"></div>')
      if menu.controller && ( @toggleable is true || ( @toggleable is false && menu.target is @target ) )
        params    = menu.params || {}
        params.el = @el.find( '#' + menu.target )
        new menu.controller( params )

    @el.find('.tabbable').addClass('hide')
    @el.find( '#' + @target ).removeClass('hide')
    @el.find('[data-toggle="tabnav"][href*="/' + @target + '"]').parent().addClass('active')

  toggle: (e) ->
    return true if @toggleable is false
    e.preventDefault()
    target = $(e.target).data('target')
    $(e.target).parents('ul').find('li').removeClass('active')
    $(e.target).parents('li').addClass('active')
    @el.find('.tabbable').addClass('hide')
    @el.find('#' + target).removeClass('hide')
#    window.scrollTo(0,0)

class App.ControllerTabs extends App.Controller
  constructor: ->
    super

  render: ->
    @html App.view('generic/tabs')(
      tabs: @tabs
    )
    @el.find('.nav-tabs li:first').addClass('active')

    for tab in @tabs
      @el.find('.tab-content').append('<div class="tab-pane" id="' + tab.target + '"></div>')
      if tab.controller
        params = tab.params || {}
        params.el = @el.find( '#' + tab.target )
        new tab.controller( params )

    @el.find('.tab-content .tab-pane:first').addClass('active')

class App.ControllerNavSidbar extends App.ControllerContent
  constructor: (params) ->
    super

    # get groups
    groups = App.Config.get(@configKey)
    groupsUnsorted = []
    for key, value of groups
      if !value.controller
        groupsUnsorted.push value

    @groupsSorted = _.sortBy( groupsUnsorted, (item) -> return item.prio )

    # get items of group
    for group in @groupsSorted
      items = App.Config.get(@configKey)
      itemsUnsorted = []
      for key, value of items
        if value.controller
          if value.parent is group.target
            itemsUnsorted.push value

      group.items = _.sortBy( itemsUnsorted, (item) -> return item.prio )


    # set active item
    selectedItem = undefined
    for group in @groupsSorted
      if group.items
        for item in group.items
          if !@target && !selectedItem
            item.active = true
            selectedItem = item
          else if @target && item.target is window.location.hash
            item.active = true
            selectedItem = item
          else
            item.active = false

    @render(selectedItem)

    if selectedItem
      new selectedItem.controller(
        el: @el.find('.main')
      )

    @bind(
      'ui:rerender'
      =>
        @render(selectedItem, true)
    )

  render: (selectedItem, force) ->
    if !$( '.' + @configKey )[0] || force
      @html App.view('generic/navbar_l2')(
        groups:     @groupsSorted
        className:  @configKey
      )
    if selectedItem
      @el.find('li').removeClass('active')
      @el.find('a[href="' + selectedItem.target + '"]').parent().addClass('active')

class App.GenericHistory extends App.ControllerModal
  events:
    'click [data-type=sortorder]': 'sortorder',
    'click .cancel': 'modalHide',
    'click .close':  'modalHide',

  constructor: ->
    super

  render: ( items, orderClass = '' ) ->

    for item in items

      item.link  = ''
      item.title = '???'

      if item.object is 'Ticket::Article'
        item.object = 'Article'
        article = App.TicketArticle.find( item.o_id )
        ticket  = App.Ticket.find( article.ticket_id )
        item.title = article.subject || ticket.title
        item.link  = article.uiUrl()

      if App[item.object]
        object     = App[item.object].find( item.o_id )
        item.link  = object.uiUrl()
        item.title = object.displayName()

      item.created_by = App.User.find( item.created_by_id )

    # set cache
    @historyListCache = items

    @html App.view('generic/history')(
      items: items
      orderClass: orderClass

      @historyListCache
    )

    @modalShow()

    # enable user popups
    @userPopups()

    # show frontend times
    @delay( @frontendTimeUpdate, 300, 'ui-time-update' )

  sortorder: (e) ->
    e.preventDefault()
    isDown = @el.find('[data-type="sortorder"]').hasClass('down')

    if isDown
      @render( @historyListCache, 'up' )
    else
      @render( @historyListCache.reverse(), 'down' )

