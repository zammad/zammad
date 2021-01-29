class GettingStartedBase extends App.ControllerWizardFullScreen
  elements:
    '.logo-preview': 'logoPreview'

  events:
    'submit form':       'submit'
    'change .js-upload': 'onLogoPick'

  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Configure Base'

    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   "#{@apiPath}/getting_started",
      processData: true,
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        # import config options
        if data.config
          for key, value of data.config
            App.Config.set(key, value)

        # render page
        @render()
    )

  render: ->

    fqdn      = App.Config.get('fqdn')
    http_type = App.Config.get('http_type')
    if !fqdn || fqdn is 'zammad.example.com'
      url = window.location.origin
    else
      url = "#{http_type}://#{fqdn}"

    organization = App.Config.get('organization')
    @replaceWith App.view('getting_started/base')(
      url:          url
      logoUrl:      @logoUrl()
      organization: organization
    )
    @$('input, select').first().focus()

  onLogoPick: (event) =>
    reader = new FileReader()

    reader.onload = (e) =>
      @logoPreview.attr('src', e.target.result)

    file = event.target.files[0]

    @hideAlerts()

    # if no file is given, about in file upload was used
    if !file
      return

    maxSiteInMb = 8
    if file.size && file.size > 1024 * 1024 * maxSiteInMb
      @showAlert( 'logo', App.i18n.translateInline('File too big, max. %s MB allowed.', maxSiteInMb ))
      @logoPreview.attr('src', '')
      return

    reader.readAsDataURL(file)

  submit: (e) =>
    e.preventDefault()
    @hideAlerts()
    @disable(e)

    @params = @formParam(e.target)
    @params.logo = @logoPreview.attr('src')
    @params.locale_default = App.i18n.detectBrowserLocale()
    @params.timezone_default = App.i18n.detectBrowserTimezone()

    store = (logoResizeDataUrl) =>
      @params.logo_resize = logoResizeDataUrl
      @ajax(
        id:          'getting_started_base'
        type:        'POST'
        url:         "#{@apiPath}/getting_started/base"
        data:        JSON.stringify(@params)
        processData: true
        success:     (data, status, xhr) =>
          if data.result is 'ok'
            for key, value of data.settings
              App.Config.set(key, value)
            if App.Config.get('system_online_service')
              @navigate 'getting_started/channel/email_pre_configured', { emptyEl: true }
            else
              @navigate 'getting_started/email_notification', { emptyEl: true }
          else
            for key, value of data.messages
              @showAlert(key, value)
            @enable(e)
        fail: =>
          @enable(e)
      )

    # add resized image
    App.ImageService.resizeForApp(@params.logo, @logoPreview.width(), @logoPreview.height(), store)

  hideAlerts: =>
    @$('.form-group').removeClass('has-error')
    @$('.alert').addClass('hide')

  showAlert: (field, message) =>
    @$("[name=#{field}]").closest('.form-group').addClass('has-error')
    @$("[name=#{field}]").closest('.form-group').find('.alert').removeClass('hide').text( App.i18n.translateInline( message ) )

App.Config.set('getting_started/base', GettingStartedBase, 'Routes')
