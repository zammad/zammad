class App.UserZoom extends App.Controller
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()


    @navupdate '#'

    App.User.full( @user_id, @render )

  meta: =>
    meta =
      url: @url()
      id:  @user_id

    user = App.User.find( @user_id )
    if user
      meta.head       = user.displayName()
      meta.title      = user.displayName()
      meta.iconClass  = @user.icon()
    meta

  url: =>
    '#user/zoom/' + @user_id

  activate: =>
    @navupdate '#'

  changed: =>
    formCurrent = @formParam( @el.find('.ticket-update') )
    diff = difference( @formDefault, formCurrent )
    return false if !diff || _.isEmpty( diff )
    return true

  render: (user) =>

    @html App.view('user_zoom')(
      user:  user
    )

    new App.UpdateTastbar(
      genericObject: user
    )

    new App.UpdateHeader(
      el:            @el
      genericObject: user
    )

    # start action controller
    new ActionRow(
      el:   @el.find('.action')
      user: user
      ui:   @
    )

    new Widgets(
      el:   @el.find('.widgets')
      user: user
      ui:   @
    )

class Widgets extends App.Controller
  constructor: ->
    super
    @render()

  render: ->

    new App.WidgetUser(
      el:      @el
      user_id: @user.id
    )

class ActionRow extends App.Controller
  events:
    'click [data-type=history]':  'history_dialog'
    'click [data-type=merge]':    'merge_dialog'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('user_zoom/actions')()

  history_dialog: (e) ->
    e.preventDefault()
    new App.UserHistory( user_id: @user.id )

  merge_dialog: (e) ->
    e.preventDefault()
    new App.TicketMerge( ticket: @ticket, task_key: @ui.task_key )

  customer_dialog: (e) ->
    e.preventDefault()
    new App.TicketCustomer( ticket: @ticket, ui: @ui )


class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      user_id:  params.user_id

    App.TaskManager.add( 'User-' + @user_id, 'UserZoom', clean_params )

App.Config.set( 'user/zoom/:user_id', Router, 'Routes' )
