class App.UserZoom extends App.Controller
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    @navupdate '#'

    start = (user) =>
      @user = user
      @render()

    App.User.retrieve( @user_id, start, true )

  meta: =>
    meta =
      url: @url()
      id:  @user_id
    if @user
      meta.head  = @user.displayName()
      meta.title = @user.displayName()
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

  release: =>
    # nothing

  render: =>
    # update taskbar with new meta data
    App.Event.trigger 'task:render'

    @html App.view('user_zoom')(
      user:  @user
    )

    # start action controller
    new ActionRow(
      el:   @el.find('.action')
      user: @user
      ui:   @
    )

    new Widgets(
      el:   @el.find('.widgets')
      user: @user
      ui:   @
    )


class Widgets extends App.Controller
  constructor: ->
    super
    @render()

  render: ->

    @html App.view('user_zoom/widgets')()

    new App.WidgetUser(
      el:      @el.find('.user_info')
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
