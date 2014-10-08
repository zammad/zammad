class Index extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    return if !@authenticate()
    @render()

  render: =>
    @html App.view('profile/avatar')()


  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    error = @form.validate(params)
    if error
      @formValidate( form: e.target, errors: error )
      return false

    @formDisable(e)

    # get data
    @locale = params['locale']
    @ajax(
      id:   'preferences'
      type: 'PUT'
      url:  @apiPath + '/users/preferences'
      data: JSON.stringify(params)
      processData: true
      success: @success
      error:   @error
    )

  success: (data, status, xhr) =>
    App.User.retrieve(
      App.Session.get( 'id' ),
      =>
        App.i18n.set( @locale )
        App.Event.trigger( 'ui:rerender' )
        App.Event.trigger( 'ui:page:rerender' )
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent( 'Successfully!' )
        )
      ,
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse( xhr.responseText )
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent( data.message )
    )

App.Config.set( 'Avatar', { prio: 1100, name: 'Avatar', parent: '#profile', target: '#profile/avatar', controller: Index }, 'NavBarProfile' )

