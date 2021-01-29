class ProfileLanguage extends App.ControllerSubContent
  requiredPermission: 'user_preferences.language'
  header: 'Language'
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>
    html    = $( App.view('profile/language')() )
    options = {}
    locales = App.Locale.all()
    for locale in locales
      options[locale.locale] = locale.name
    configure_attributes = [
      { name: 'locale', display: '', tag: 'searchable_select', null: false, class: 'input', options: options, default: App.i18n.get() },
    ]

    @form = new App.ControllerForm(
      el:        html.find('.js-language')
      model:     { configure_attributes: configure_attributes }
      autofocus: false
    )
    @html html

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    error  = @form.validate(params)
    if error
      @formValidate( form: e.target, errors: error )
      return false

    @formDisable(e)

    # get data
    @locale = params['locale']
    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify(params)
      processData: true
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    App.User.full(
      App.Session.get('id'),
      =>
        App.i18n.set(@locale)
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

App.Config.set('Language', { prio: 1000, name: 'Language', parent: '#profile', target: '#profile/language', controller: ProfileLanguage, permission: ['user_preferences.language'] }, 'NavBarProfile')
