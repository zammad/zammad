class Exchange extends App.ControllerIntegrationBase
  featureIntegration: 'exchange_integration'
  featureName: __('Exchange')
  featureConfig: 'exchange_config'
  description: [
    [__('This service enables Zammad to connect with your Exchange server.')]
  ]
  events:
    'change .js-switch input': 'switch'

  constructor: ->
    super

    if @success_code is '1'
      @navigate '#system/integration/exchange'
    else if @error_code is 'AADSTS65004'
      new App.AdminConsentInfo(container: @container)

  render: =>
    super

    new Form(
      el: @$('.js-form')
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'EWS'
    )

  switch: =>
    super
    active = @$('.js-switch input').prop('checked')
    if active
      job_start = =>
        @ajax(
          id:   'jobs_config'
          type: 'POST'
          url:  "#{@apiPath}/integration/exchange/job_start"
          processData: true
          success: (data, status, xhr) =>
            @render(true)
        )

      App.Delay.set(
        job_start,
        600,
        'job_start',
      )

class Form extends App.Controller
  elements:
    '.js-lastImport': 'lastImport'
    '.js-wizard':     'wizardButton'
  events:
    'click .js-wizard':                 'startWizard'
    'click .js-start-sync':             'startSync'
    'click .js-new-app':                'newApp'
    'click .js-delete-app':             'deleteApp'
    'click .js-reauthenticate-app':     'reauthenticateApp'
    'click .js-config-app':             'configApp'
    'click .js-admin-consent':          'adminConsent'
    'change .js-authentication-method': 'changeAuthenticationMethod'

  constructor: ->
    super
    @render()
    @lastResult()
    @activeDryRun()

  currentConfig: ->
    App.Setting.get('exchange_config') || {}

  setConfig: (value) =>
    App.Setting.set('exchange_config', value, {notify: true})
    @startSync()

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

  render: (top = false) =>
    @config = @currentConfig()

    folders = []
    if !_.isEmpty(@config.folders)
      for folder_id in @config.folders
        folders.push @config.wizardData.backend_folders[folder_id]

    @html App.view('integration/exchange')(
      config: @config,
      folders: folders
    )
    if _.isEmpty(@config)
      @$('.js-notConfigured').removeClass('hide')
      @$('.js-summary').addClass('hide')
    else
      @$('.js-notConfigured').addClass('hide')
      @$('.js-summary').removeClass('hide')

    @interval(@loadExchangeData, 30000)
    @loadExchangeData(true)

    if top
      a = =>
        @scrollToIfNeeded($('.content.active .page-header'))
      @delay(a, 500)

  loadExchangeData: (initial = false) =>
    @startLoading()
    @ajax(
      id:   'exchange_index'
      type: 'GET'
      url:  "#{@apiPath}/integration/exchange/index"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @exchange_oauth = data.oauth

        # if no exchange app is registered, show intro
        external_credential = App.ExternalCredential.findByAttribute('name', 'exchange')
        if !external_credential
          @$('.js-oAuthContent').html($(App.view('exchange/oauth_intro')())).removeClass('hide')
        else
          @$('.js-oAuthContent').html($(App.view('exchange/token_information')(
            oauth: data.oauth
            external_credential: external_credential
          ))).removeClass('hide')

        @setAuthenticationMethod(initial)
    )
    true

  setAuthenticationMethod: (initial) ->
    method = @el.find('.js-authentication-method').val() || 'basic'
    if initial
      method = 'basic'
      if !_.isEmpty(@exchange_oauth)
        method = 'oauth'

    @el.find('.js-authentication-method').val(method).trigger('change')

  changeAuthenticationMethod: ->
    method = @el.find('.js-authentication-method').val()
    if method is 'basic'
      @el.find('.js-oAuthContent').addClass('hide')
    else
      @el.find('.js-oAuthContent').removeClass('hide')

    @currentAuthenticationMethod = method

  configApp: =>
    new AppConfig(
      container: @el.parents('.content')
      callbackUrl: @callbackUrl
    )

  newApp: (e) ->
    window.location.href = "#{@apiPath}/external_credentials/exchange/link_account"

  adminConsent: (e) ->
    window.location.href = "#{@apiPath}/external_credentials/exchange/link_account?prompt=consent"

  deleteApp: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    new App.ControllerConfirm(
      message: __('Are you sure?')
      callback: =>
        @ajax(
          id:   'exchange_delete'
          type: 'DELETE'
          url:  "#{@apiPath}/integration/exchange/oauth"
          success: (data, status, xhr) =>
            @render()
        )
      container: @el.closest('.content')
    )

  reauthenticateApp: (e) =>
    e.preventDefault()
    window.location.href = "#{@apiPath}/external_credentials/exchange/link_account"

  startSync: =>
    @ajax(
      id:   'jobs_config'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/job_start"
      processData: true
      success: (data, status, xhr) =>
        @render(true)
        @lastResult()
    )

  startWizard: (e) =>
    e.preventDefault()
    new ConnectionWizard(
      container: @el.closest('.content')
      config: @config
      currentAuthenticationMethod: @currentAuthenticationMethod
      callback: (config) =>
        @setConfig(config)
    )

  lastResult: =>
    @ajax(
      id:   'jobs_start_index'
      type: 'GET'
      url:  "#{@apiPath}/integration/exchange/job_start"
      processData: true
      success: (job, status, xhr) =>
        if !_.isEmpty(job)
          if !@lastResultShowJob || @lastResultShowJob.updated_at != job.updated_at
            @lastResultShowJob = job
            @lastResultShow(job)
            if job.finished_at
              @wizardButton.attr('disabled', false)
            else
              @wizardButton.attr('disabled', true)
        @delay(@lastResult, 5000)
    )

  lastResultShow: (job) =>
    if _.isEmpty(job)
      @lastImport.html('')
      return
    if !job.result.roles
      job.result.roles = {}
    for role_id, statistic of job.result.role_ids
      role = App.Role.find(role_id)
      job.result.roles[role.displayName()] = statistic
    el = $(App.view('integration/exchange_last_import')(job: job))
    @lastImport.html(el)

  activeDryRun: =>
    @ajax(
      id:   'jobs_try_index'
      type: 'GET'
      url:  "#{@apiPath}/integration/exchange/job_try"
      data:
        finished: false
      processData: true
      success: (job, status, xhr) =>
        return if _.isEmpty(job)

        # show analyzing
        new ConnectionWizard(
          container: @el.closest('.content')
          config: job.payload.params
          start: 'tryLoop'
          callback: (config) =>
            @wizardButton.attr('disabled', false)
            @setConfig(config)
        )
        @wizardButton.attr('disabled', true)
    )

class State
  @current: ->
    App.Setting.get('exchange_integration')

class ConnectionWizard extends App.ControllerWizardModal
  slideMethod:
    'js-folders': 'foldersShow'
    'js-mapping': 'mappingShow'

  events:
    'submit form.js-discover':                 'discoverParams'
    'submit form.js-discoverCertificateIssue': 'discoverConfig'
    'submit form.js-folders':                  'mapping'
    'click .js-cancelSsl':                     'showSlideDiscover'
    'click .js-mapping .js-submitTry':         'mappingChange'
    'click .js-try .js-submitSave':            'save'
    'click .js-close':                         'hide'
    'click .js-remove':                        'removeRow'
    'click .js-userMappingForm .js-add':       'addUserMapping'
    'click .js-goToSlide':                     'goToSlide'

  elements:
    '.modal-body': 'body'
    '.js-foldersSelect': 'foldersSelect'
    '.js-folders .js-submitTry': 'foldersSelectSubmit'
    '.js-userMappingForm': 'userMappingForm'
    '.js-expertForm': 'expertForm'

  constructor: ->
    super

    @wizardConfig = $.extend(true, {}, @config)

    if @currentAuthenticationMethod isnt undefined
      @wizardConfig.auth_type = @currentAuthenticationMethod

    if @container
      @el.addClass('modal--local')

    @render()

    @el.modal
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    .on
      'show.bs.modal':   @onShow
      'shown.bs.modal': =>
        @el.addClass('modal--ready')
        @onShown()
      'hidden.bs.modal': =>
        @el.remove()

    if @slide
      @showSlide(@slide)

  render: =>
    @ajax(
      id:   'exchange_index'
      type: 'GET'
      url:  "#{@apiPath}/integration/exchange/index"
      processData: true
      success: (data, status, xhr) =>
        @exchange_oauth = data.oauth

        @html App.view('integration/exchange_wizard')(
          exchange_oauth: @exchange_oauth
        )

        @showDiscoverDetails()
        @presetAuthenticationMethod()

        if @start
          @[@start]()
    )

  save: (e) =>
    e.preventDefault()
    @callback(@wizardConfig)
    @hide(e)

  showSlide: (slide) =>
    method = @slideMethod[slide]
    if method && @[method]
      @[method](true)
    super

  showDiscoverDetails: =>
    @$('.js-discover input[name="endpoint"]').val(@wizardConfig.endpoint)

    if @wizardConfig.auth_type is 'basic'
      @$('.js-discover input[name="user"]').val(@wizardConfig.user)
      @$('.js-discover input[name="password"]').val(@wizardConfig.password)

  showSlideDiscover: =>
    @showSlide('js-discover')

  discoverParams: (e) ->
    e.preventDefault()
    params = @formParam(e.target)

    @wizardConfig.endpoint           = params.endpoint
    @wizardConfig.disable_ssl_verify = params.disable_ssl_verify

    if @wizardConfig.auth_type is 'basic'
      @wizardConfig.user      = params.user
      @wizardConfig.password  = params.password

    @discover(params)

  discoverConfig: (e) ->
    e.preventDefault()
    @discover(@wizardConfig)

  discover: (params) =>
    @showSlide('js-connect')

    @ajax(
      id:   'exchange_discover'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/autodiscover"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result isnt 'ok' && @wizardConfig.auth_type isnt 'oauth'
          @handleCertificateIssue(
            message:     data.message
            wizardClass: 'js-discover'
          )
          return

        @folders()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-discover')
        @showAlert('js-discover', details.error || __('Server operation failed.'))
    )

  folders: =>
    @showSlide('js-analyze')

    @ajax(
      id:   'exchange_folders'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/folders"
      data: JSON.stringify(@wizardConfig)
      processData: true
      success: (data, status, xhr) =>
        if data.result isnt 'ok'
          @handleCertificateIssue(
            message:     data.message
            wizardClass: 'js-discover'
          )
          return

        @wizardConfig.wizardData = {}
        @wizardConfig.wizardData.backend_folders = data.folders || []

        @foldersShow()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-discover')
        @showAlert('js-discover', details.error || __('Server operation failed.'))
    )

  foldersShow: (alreadyShown) =>
    @showSlide('js-folders') if !alreadyShown
    @foldersSelect.html(@createColumnSelection('folders', @wizardConfig.wizardData.backend_folders, @wizardConfig.folders))
    if @wizardConfig.folders && @wizardConfig.folders.length > 0
      @foldersSelectSubmit.removeClass('is-disabled')

  createColumnSelection: (name, options, selected) ->
    return App.UiElement.column_select.render(
      name: name
      null: false
      nulloption: false
      options: options
      value: selected
      onChange: (val) =>
        if _.isArray(val) && val.length > 0
          @foldersSelectSubmit.removeClass('is-disabled')
        else
          @foldersSelectSubmit.addClass('is-disabled')
    )

  handleCertificateIssue: (params) =>
    @wizardConfig.disable_ssl_verify = 1

    if params.message.indexOf('certificate') is -1
      @showSlide(params.wizardClass)
      @showAlert(params.wizardClass, params.message)
    else
      wizardClass = "#{params.wizardClass}CertificateIssue"

      domain = @domainFromMessageOrEmail(
        message: params.message
      )

      wizardSlide = App.view('integration/exchange_certificate_issue')(
        wizardClass: wizardClass
        domain:      domain
      )

      @$('.js-certificateIssuePlaceholder').html(wizardSlide)

      @showSlide(wizardClass)

  domainFromMessageOrEmail: (params) ->

    # try to extract the hostname from the error message
    hostname = params.message.match(/hostname[ ]\"([^\"]+)"/i)
    if hostname
      return hostname[1]

    # try to extract it from the given user
    emailDomain = @wizardConfig.user.match(/@(.*)$/)
    if emailDomain
      return emailDomain[1]

    # fallback to user - better than no value?!
    return @wizardConfig.user

  mapping: (e) =>
    e.preventDefault()

    params = @formParam(e.target)
    @wizardConfig.folders = params.folders

    # folders might be a single selection so we
    # have to ensure that is an Array so the
    # backend and frontend can handle it properly
    if typeof @wizardConfig.folders is 'string'
      @wizardConfig.folders = [ @wizardConfig.folders ]

    @showSlide('js-analyze')

    @ajax(
      id:   'exchange_mapping'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/mapping"
      data: JSON.stringify(@wizardConfig)
      processData: true
      success: (data, status, xhr) =>
        if data.result isnt 'ok'
          @showSlide('js-folders')
          @showAlert('js-folders', data.message)
          return

        attributes = {}
        for key, value of App.User.attributesGet()
          continue if key == 'login'
          if (value.tag is 'input' || value.tag is 'richtext' || value.tag is 'textarea')  && value.type isnt 'password'
            attributes[key] = value.display || key

        @wizardConfig.wizardData.attributes         = attributes
        @wizardConfig.wizardData.backend_attributes = data.attributes

        @mappingShow()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-folders')
        @showAlert('js-folders', details.error || __('Server operation failed.'))
    )

  mappingShow: (alreadyShown) =>
    @showSlide('js-mapping') if !alreadyShown
    user_attribute_map = @wizardConfig.attributes

    if _.isEmpty(user_attribute_map)
      user_attribute_map =
        given_name: 'firstname'
        surname: 'lastname'
        'email_addresses.emailaddress1': 'email'
        'phone_numbers.businessphone': 'phone'

    @userMappingForm.find('tbody tr.js-entry').remove()
    @userMappingForm.find('tbody tr').before(@buildRowsUserMap(user_attribute_map))

  mappingChange: (e) =>
    e.preventDefault()

    # user map
    attributes = @formParam(@userMappingForm)
    for key in ['source', 'dest']
      if !_.isArray(attributes[key])
        attributes[key] = [attributes[key]]

    attributes_local = {}
    length           = attributes.source.length-1
    for count in [0..length]
      if attributes.source[count] && attributes.dest[count]
        attributes_local[attributes.source[count]] = attributes.dest[count]
    @wizardConfig.attributes = attributes_local

    @tryShow()

  buildRowsUserMap: (user_attribute_map) =>
    el = []
    for source, dest of user_attribute_map
      continue if !(source of @wizardConfig.wizardData.backend_attributes)
      el.push @buildRowUserAttribute(source, dest)
    el

  buildRowUserAttribute: (source, dest) =>
    el = $(App.view('integration/exchange_user_attribute_row')())
    el.find('.js-exchangeAttribute').html(@createSelection('source', @wizardConfig.wizardData.backend_attributes, source))
    el.find('.js-userAttribute').html(@createSelection('dest', @wizardConfig.wizardData.attributes, dest))
    el

  createSelection: (name, options, selected, unknown) ->
    return App.UiElement.searchable_select.render(
      name: name
      multiple: false
      limit: 100
      null: false
      nulloption: false
      options: options
      value: selected
      unknown: unknown
      class: 'form-control--small'
    )

  removeRow: (e) ->
    e.preventDefault()
    $(e.target).closest('tr').remove()

  addUserMapping: (e) =>
    e.preventDefault()
    @userMappingForm.find('tbody tr').last().before(@buildRowUserAttribute())

  presetAuthenticationMethod: ->
    current_method = @wizardConfig.auth_type || 'basic'
    required       = true
    if current_method is 'basic'
      @el.find('table.basic-auth, p.basic-auth').removeClass('hide')
      @el.find('input[name="endpoint"]').val('')
    else if current_method is 'oauth'
      required = false
      @el.find('table.basic-auth, p.basic-auth').addClass('hide')
      @el.find('input[name="endpoint"]').val(@el.find('input[name="endpoint"]').prop('placeholder'))

    @el.find('table.basic-auth input').prop('required', required)

  tryShow: (e) =>
    if e
      e.preventDefault()
    @showSlide('js-analyze')

    # create import job
    @ajax(
      id:   'exchange_try'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/job_try"
      data: JSON.stringify(@wizardConfig)
      processData: true
      success: (data, status, xhr) =>
        @tryLoop()
    )

  tryLoop: =>
    @showSlide('js-dry')
    @ajax(
      id:   'jobs_try_index'
      type: 'GET'
      url:  "#{@apiPath}/integration/exchange/job_try"
      data:
        finished: true
      processData: true
      success: (job, status, xhr) =>
        if job.result && (job.result.error || job.result.info)
          @showSlide('js-error')
          @showAlert('js-error', (job.result.error || job.result.info))
          return

        if job.result && _.keys(job.result).length > 0
          @$('.js-preprogress').addClass('hide')
          @$('.js-analyzing').removeClass('hide')

          @$('.js-progress progress').attr('value', job.result.sum)
          @$('.js-progress progress').attr('max', job.result.total)

        if job.finished_at
          # reset initial state in case the back button is used
          @$('.js-preprogress').removeClass('hide')
          @$('.js-analyzing').addClass('hide')

          @tryResult(job)
        else
          @delay(@tryLoop, 4000)
    )

  tryResult: (job) =>
    @showSlide('js-try')
    el = $(App.view('integration/exchange_summary')(job: job))
    @el.find('.js-summary').html(el)

class AppConfig extends App.ControllerModal
  head: __('Connect Exchange App')
  shown: true
  button: 'Connect'
  buttonCancel: true
  small: true

  content: ->
    @external_credential = App.ExternalCredential.findByAttribute('name', 'exchange')
    content = $(App.view('exchange/app_config')(
      external_credential: @external_credential
      callbackUrl: @callbackUrl
    ))
    content.find('.js-select').on('click', (e) =>
      @selectAll(e)
    )
    content

  onSubmit: (e) =>
    @formDisable(e)

    # verify app credentials
    @ajax(
      id:   'exchange_app_verify'
      type: 'POST'
      url:  "#{@apiPath}/external_credentials/exchange/app_verify"
      data: JSON.stringify(@formParams())
      processData: true
      success: (data, status, xhr) =>
        if data.attributes
          if !@external_credential
            @external_credential = new App.ExternalCredential
          @external_credential.load(name: 'exchange', credentials: data.attributes)
          @external_credential.save(
            done: =>
              @close()
            fail: =>
              @el.find('.alert').removeClass('hidden').text(__('The entry could not be created.'))
          )
          return
        @formEnable(e)
        @el.find('.alert').removeClass('hidden').text(data.error || __('App could not be verified.'))
    )

App.Config.set(
  'IntegrationExchange'
  {
    name: __('Exchange')
    target: '#system/integration/exchange'
    description: __('Exchange integration for contacts management.')
    controller: Exchange
    state: State
    permission: ['admin.integration.exchange']
  }
  'NavBarIntegrations'
)
