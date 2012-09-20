$ = jQuery.sub()
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
      model:      @genericObject,
      params:     @item,
      autofocus:  true,
    )

    @modalShow()

  submit: (e) ->
    @log 'submit'
    e.preventDefault()
    params = @formParam(e.target)
    ###
    for num in [1..199]
      user = new User
      params.login = 'login_c' + num
      user.updateAttributes(params)
    return false
    ###
    object = new @genericObject
    object.load(params)
    
    # validate
    errors = object.validate()
    if errors
      @log 'error new', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # save object
    object.save(
      success: =>
        @modalHide()
      error: =>
        @log 'errors'
        @modalHide()
    )

class App.ControllerGenericEdit extends App.ControllerModal
  constructor: (params) ->
    super
    @log 'ControllerGenericEditWindow', params

    # fetch item on demand
    if @genericObject.exists(params.id)
      @item = @genericObject.find(params.id)
      @render()
    else
      @genericObject.bind 'refresh', =>
        @log 'changed....'
        @item = @genericObject.find(params.id)
        @render()
        @genericObject.unbind 'refresh'
      @genericObject.fetch( id: params.id) 
    
  render: ->
    @html App.view('generic/admin/edit')( head: @pageData.object )

    new App.ControllerForm(
      el:         @el.find('#object_edit'),
      model:      @genericObject,
      params:     @item,
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
      @log 'error new', errors
      @formValidate( form: e.target, errors: errors )
      return false

    @log 'save....'
    # save object
    @item.save(
      success: =>
        @modalHide()
      error: =>
        @log 'errors'

        @modalHide()
    )

class App.ControllerGenericIndex extends App.Controller
  events:
    'click [data-type=edit]':    'edit'
    'click [data-type=destroy]': 'destroy'
    'click [data-type=new]':     'new'

  constructor: ->
    super

    # set controller to active
    Config['ActiveController'] = @pageData.navupdate

    # set title
    @title @pageData.title

    # set nav bar    
    @navupdate @pageData.navupdate

    # bind render after a change is done
    @genericObject.bind 'refresh change', @render
    @genericObject.bind 'ajaxError', (rec, msg) =>
      @log 'ajax notice', msg.status
      if msg.status is 401
        @log 'ajax error', rec, msg, msg.status
#        @navigate @pageData.navupdate
#        alert('relogin')
        @navigate 'login'

    # execute fetch, if needed
    if !@genericObject.count() || true
#    if !@genericObject.count()

      # prerender without content    
      @render()

      # fetch all
#      @log 'oooo', @genericObject.model
#      @genericObject.deleteAll()
      @genericObject.fetch()
    else
      @render()

  render: =>

    return if Config['ActiveController'] isnt @pageData.navupdate

    objects = @genericObject.all()

    # remove ignored items from collection
    if @ignoreObjectIDs
      objects = _.filter(objects, (item) ->
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
    table = @table(
      model:   @genericObject,
      objects: objects,
    )
    @el.find('.table-overview').append(table)

  edit: (e) =>
    e.preventDefault()
    item = $(e.target).item(@genericObject)
    new App.ControllerGenericEdit(
      id: item.id,
      pageData: @pageData,
      genericObject: @genericObject
    )

  destroy: (e) ->
    item = $(e.target).item(@genericObject)
    item.destroy() if confirm('Sure?')

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:      @pageData,
      genericObject: @genericObject
    )

class App.ControllerLevel2 extends App.Controller
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
