class App.SettingsForm extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  render: =>

    # serach area settings
    settings = App.Setting.search(
      filter:
        area: @area
    )

    # filter online service settings
    if App.Config.get('system_online_service')
      settings = _.filter(settings, (setting) ->
        return if setting.online_service
        return if setting.preferences && setting.preferences.online_service_disable
        setting
      )
      return if _.isEmpty(settings)

    # sort by prio
    settings = _.sortBy( settings, (setting) ->
      return if !setting.preferences
      setting.preferences.prio
    )

    localEl = $( App.view('settings/form')(
      settings: settings
    ))

    for setting in settings
      configure_attributes = setting.options['form']
      value = App.Setting.get(setting.name)
      params = {}
      params[setting.name] = value
      new App.ControllerForm(
        el: localEl.find("[data-name=#{setting.name}]")
        model: { configure_attributes: configure_attributes, className: '' }
        params: params
      )
    @html localEl

  update: (e) =>
    e.preventDefault()
    @formDisable(e)
    params = @formParam(e.target)

    ui = @
    count = 0
    for name, value of params
      if App.Setting.findByAttribute('name', name)
        count += 1
        App.Setting.set(
          name,
          value,
          done: ->
            ui.formEnable(e)
            count -= 1
            if count == 0
              App.Event.trigger 'notify', {
                type:    'success'
                msg:     App.i18n.translateContent('Update successful!')
                timeout: 2000
              }

              # rerender ui || get new collections and session data
              if @preferences
                if @preferences.render
                  App.Event.trigger( 'ui:rerender' )

                if @preferences.session_check
                  App.Auth.loginCheck()

          fail: (settings, details) ->
            App.Event.trigger 'notify', {
              type:    'error'
              msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
              timeout: 2000
            }
        )

class App.SettingsArea extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  render: =>

    # serach area settings
    settings = App.Setting.search(
      filter:
        area: @area
    )

    # filter online service settings
    if App.Config.get('system_online_service')
      settings = _.filter(settings, (setting) ->
        return if setting.online_service
        return if setting.preferences && setting.preferences.online_service_disable
        setting
      )
      return if _.isEmpty(settings)

    # sort by prio
    settings = _.sortBy( settings, (setting) ->
      return if !setting.preferences
      setting.preferences.prio
    )

    elements = []
    for setting in settings
      if setting.name is 'product_logo'
        item = new App.SettingsAreaLogo( setting: setting )
      else
        item = new App.SettingsAreaItem( setting: setting )
      elements.push item.el

    @html elements

class App.SettingsAreaItem extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>

    # defaults
    directValue = 0
    for item in @setting.options['form']
      directValue += 1
    if directValue > 1
      for item in @setting.options['form']
        item['default'] = @setting.state_current.value[item.name]
    else
      item['default'] = @setting.state_current.value

    # form
    @configure_attributes = @setting.options['form']

    # item
    @html App.view('settings/item')(
      setting: @setting
    )

    new App.ControllerForm(
      el: @el.find('.form-item'),
      model: { configure_attributes: @configure_attributes, className: '' }
      autofocus: false
    )

  update: (e) =>
    e.preventDefault()
    @formDisable(e)
    params = @formParam(e.target)

    directValue = 0
    directData  = undefined
    for item in @setting.options['form']
      directValue += 1
      directData  = params[item.name]

    if directValue > 1
      state_current = {
        value: params
      }
      #App.Config.set((@setting.name, params)
    else
      state_current = {
        value: directData
      }
      #App.Config.set(@setting.name, directData)

    @setting['state_current'] = state_current
    ui = @
    @setting.save(
      done: =>
        ui.formEnable(e)
        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent('Update successful!')
          timeout: 2000
        }

        # rerender ui || get new collections and session data
        if @setting.preferences
          if @setting.preferences.render
            ui.render()
            App.Event.trigger( 'ui:rerender' )

          if @setting.preferences.session_check
            App.Auth.loginCheck()
      fail: (settings, details) ->
        ui.formEnable(e)
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 2000
        }
    )

class App.SettingsAreaLogo extends App.Controller
  elements:
    '.logo-preview': 'logoPreview'

  events:
    'submit form':       'submit'
    'change .js-upload': 'onLogoPick'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('settings/logo')(
      setting: @setting
      logoUrl: @logoUrl()
    )

  onLogoPick: (event) =>
    reader = new FileReader()

    reader.onload = (e) =>
      @logoPreview.attr('src', e.target.result)

    file = event.target.files[0]

    # if no file is given, about in file upload was used
    if !file
      return

    maxSiteInMb = 8
    if file.size && file.size > 1024 * 1024 * maxSiteInMb
      App.Event.trigger 'notify', {
        type:    'error'
        msg:     App.i18n.translateContent('File too big, max. %s MB allowed.', maxSiteInMb )
        timeout: 2000
      }
      @logoPreview.attr( 'src', '' )
      return

    reader.readAsDataURL(file)

  submit: (e) =>
    e.preventDefault()
    @formDisable(e)

    # get params
    @params = @formParam(e.target)

    # add logo
    @params.logo = @logoPreview.attr('src')

    store = (logoResizeDataUrl) =>

      # store image
      @params.logo_resize = logoResizeDataUrl
      @ajax(
        id:          "setting_image_#{@setting.id}"
        type:        'PUT'
        url:         "#{@apiPath}/settings/image/#{@setting.id}"
        data:        JSON.stringify(@params)
        processData: true
        success:     (data, status, xhr) =>
          @formEnable(e)
          if data.result is 'ok'
            App.Event.trigger 'notify', {
              type:    'success'
              msg:     App.i18n.translateContent('Update successful!')
              timeout: 2000
            }

            for key, value of data.settings
              App.Config.set( key, value )
          else
            App.Event.trigger 'notify', {
              type:    'error'
              msg:     App.i18n.translateContent(data.message)
              timeout: 2000
            }

        fail: =>
          @formEnable(e)
      )

    # add resized image
    App.ImageService.resizeForApp( @params.logo, @logoPreview.width(), @logoPreview.height(), store )
