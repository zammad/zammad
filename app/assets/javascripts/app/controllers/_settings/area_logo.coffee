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
    localElement = $(App.view('settings/logo')(
      setting: @setting
    ))
    localElement.find('.js-loginPreview').html( App.view('generic/login_preview')(
      logoUrl: @logoUrl()
      logoChange: true
      maintananceChange: false
    ))
    @html localElement

  onLogoPick: (event) =>
    reader = new FileReader()

    reader.onload = (e) =>
      @logoPreview.attr('src', e.target.result)

    file = event.target.files[0]

    # if no file is given, about in file upload was used
    return if !file

    maxSiteInMb = 8
    if file.size && file.size > 1024 * 1024 * maxSiteInMb
      App.Event.trigger 'notify', {
        type:    'error'
        msg:     App.i18n.translateContent('File too big, max. %s MB allowed.', maxSiteInMb)
        timeout: 2000
      }
      @logoPreview.attr('src', '')
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
            for setting in data.settings
              value = App.Setting.get(setting.name)
              App.Config.set(name, value)
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
    App.ImageService.resizeForApp(@params.logo, @logoPreview.width(), @logoPreview.height(), store)
