class App.SettingsAreaProxy extends App.Controller
  events:
    'submit form': 'update'
    'click .js-submit': 'update'
    'click .js-test': 'test2'

  constructor: ->
    super
    @render()

  render: =>
    @html App.view('settings/proxy')(
      setting: App.Setting.findByAttribute('name', 'proxy')
      proxy: App.Setting.get('proxy')
      proxy_username: App.Setting.get('proxy_username')
      proxy_password: App.Setting.get('proxy_password')
    )

  update: (e) =>
    e.preventDefault()
    @formDisable(e)
    params = @formParam(e)
    console.log('params', params)
    App.Setting.set('proxy', params.proxy)
    App.Setting.set('proxy_username', params.proxy_username)
    App.Setting.set('proxy_password', params.proxy_password)
    @formEnable(e)
    @render()

  test2: (e) =>
    e.preventDefault()
    params = @formParam(e)
    @ajax(
      id:          'proxy_test'
      type:        'POST'
      url:         "#{@apiPath}/proxy"
      data:        JSON.stringify(params)
      processData: true
      success:     (data, status, xhr) =>
        if data.result is 'success'
          @$('.js-test').addClass('hide')
          @$('.js-submit').removeClass('hide')
          App.Event.trigger 'notify', {
            type:    'success'
            msg:     App.i18n.translateContent('Connection test successful')
            timeout: 2000
          }
          return
        new App.ControllerConfirm(
          head: 'Error'
          message: data.message
          buttonClass: 'btn--success'
          buttonCancel: false
          buttonSubmit: 'Close'
          container: @el.closest('.content')
        )
    )

