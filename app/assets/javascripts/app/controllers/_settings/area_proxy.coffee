class App.SettingsAreaProxy extends App.Controller
  events:
    'submit form': 'update'
    'click .js-submit': 'update'
    'click .js-test': 'testConnection'

  constructor: ->
    super
    @render()

  render: =>
    @html App.view('settings/proxy')(
      setting: App.Setting.findByAttribute('name', 'proxy')
      proxy: App.Setting.get('proxy')
      proxy_username: App.Setting.get('proxy_username')
      proxy_password: App.Setting.get('proxy_password')
      proxy_no: App.Setting.get('proxy_no')
    )

  update: (e) =>
    e.preventDefault()
    @formDisable(e)
    params = @formParam(e)
    App.Setting.set('proxy', params.proxy)
    App.Setting.set('proxy_username', params.proxy_username)
    App.Setting.set('proxy_password', params.proxy_password)
    App.Setting.set('proxy_no', params.proxy_no)
    @formEnable(e)
    @render()

  testConnection: (e) =>
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

