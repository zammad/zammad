class Index extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    return if !@authenticate()
    @render()

  render: =>

    # item
    html = $( App.view('profile/password')() )

    configure_attributes = [
      { name: 'password_old', display: 'Current Password', tag: 'input', type: 'password', limit: 100, null: false, class: 'input span4', single: true  },
      { name: 'password_new', display: 'New Password',     tag: 'input', type: 'password', limit: 100, null: false, class: 'input span4',  },
    ]

    @form = new App.ControllerForm(
      el:        html.find('.password_item')
      model:     { configure_attributes: configure_attributes }
      autofocus: false
    )
    @html html

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    error = @form.validate(params)
    if error
      @formValidate( form: e.target, errors: error )
      return false

    @formDisable(e)

    # get data
    App.Com.ajax(
      id:   'password_reset'
      type: 'POST'
      url:  'api/users/password_change'
      data: JSON.stringify(params)
      processData: true
      success: @success
      error:   @error
    )

  success: (data, status, xhr) =>
    @render()
    @notify(
      type: 'success'
      msg:  App.i18n.translateContent( 'Password changed successfully!' )
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse( xhr.responseText )
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent( data.message )
    )

App.Config.set( 'Password', { prio: 2000, name: 'Password', parent: '#profile', target: '#profile/password', controller: Index }, 'NavBarProfile' )

