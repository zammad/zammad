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
          ui.callback( @ )
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
      el:         @el.find('#object_edit'),
      model:      App[ @genericObject ],
      params:     @item,
      required:   @required,
      autofocus:  true,
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
          ui.callback( @ )
        ui.modalHide()

      error: =>
        ui.log 'errors'
        ui.modalHide()
    )

class App.ControllerGenericIndex extends App.ControllerContent
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
    App[ @genericObject ].fetch()

  release: =>
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
      head:    @pageData.objects,
      notes:   @pageData.notes,
      buttons: @pageData.buttons,
      menus:   @pageData.menus,
    )

    # append content table
    new App.ControllerTable(
      el:      @el.find('.table-overview'),
      model:   App[ @genericObject ],
      objects: objects,
    )

  edit: (e) =>
    e.preventDefault()
    item = $(e.target).item( App[ @genericObject ] )
    new App.ControllerGenericEdit(
      id:            item.id,
      pageData:      @pageData,
      genericObject: @genericObject
    )

  destroy: (e) ->
    item = $(e.target).item( App[ @genericObject ] )
    new DestroyConfirm(
      item: item
    )

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:      @pageData,
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
      backdrop: true,
      keyboard: true,
    )

  submit: (e) =>
    @modalHide()
    @item.destroy()

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
      page:     @page,
      menus:    @menu,
      type:     @type,
      target:   @target,
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
      tabs: @tabs,
    )
    @el.find('.nav-tabs li:first').addClass('active')

    for tab in @tabs
      @el.find('.tab-content').append('<div class="tab-pane" id="' + tab.target + '"></div>')
      if tab.controller
        params = tab.params || {}
        params.el = @el.find( '#' + tab.target )
        new tab.controller( params )

    @el.find('.tab-content .tab-pane:first').addClass('active')
