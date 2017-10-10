class Index extends App.ControllerSubContent
  requiredPermission: 'user_preferences.email_header'
  header: 'EmailHeader'
  events:
    'submit form': 'update'

  constructor: ->
    super
    @header_pre_val = true
    @getHeaderPre()
    

  render: =>
    html    = $( App.view('profile/email_header')() )
    options = {}
    locales = ["Yes", "No"]
    for locale in locales
      options[locale] = locale
    configure_attributes = [
      { name: 'header_pre', display: '', tag: 'select', null: false, class: 'select', options: options, default: @header_pre_val },
    ]

    @form = new App.ControllerForm(
      el: html.find('.header_pre')
      model:     { configure_attributes: configure_attributes }
      autofocus: false
    )
    @html html

  getHeaderPre: =>
    @ajax(
      id: 'header_pre'
      type: 'GET'
      url:  "#{@apiPath}/users/get_preferences"
      processData: true
      success: (data, status, xhr) =>
        console.log("data----", data)
        @header_pre_val = data.header_pre
        @render()
    )



  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    error  = @form.validate(params)
    if error
      @formValidate( form: e.target, errors: error )
      return false

    @formDisable(e)

    # get data
    @locale = params['header_pre']
    @ajax(
      id:          'header_pre'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify({user:params})
      processData: true
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    App.User.full(
      App.Session.get('id'),
      =>
        App.Event.trigger('ui:rerender')
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent('Successful!')
        )
      ,
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set('EmailHeader', { prio: 1000, name: 'EmailHeader', parent: '#profile', target: '#profile/email_header', controller: Index, permission: ['user_preferences.header_pre'] }, 'NavBarProfile')
