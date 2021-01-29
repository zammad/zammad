class Exchange extends App.ControllerIntegrationBase
  featureIntegration: 'exchange_integration'
  featureName: 'Exchange'
  featureConfig: 'exchange_config'
  description: [
    ['This service enables Zammad to connect with your Exchange server.']
  ]
  events:
    'change .js-switch input': 'switch'

  render: =>
    super
    new Form(
      el: @$('.js-form')
    )

    #new App.ImportJob(
    #  el: @$('.js-importJob')
    #  facility: 'exchange'
    #)

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'exchange'
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
    '.js-wizard': 'wizardButton'
  events:
    'click .js-wizard': 'startWizard'
    'click .js-start-sync': 'startSync'

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

    if top
      a = =>
        @scrollToIfNeeded($('.content.active .page-header'))
      @delay(a, 500)

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
          config: job.payload
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
  wizardConfig: {}
  slideMethod:
    'js-folders': 'foldersShow'
    'js-mapping': 'mappingShow'

  events:
    'submit form.js-discover':                 'discover'
    'submit form.js-discoverCertificateIssue': 'discover'
    'submit form.js-bind':                     'folders'
    'submit form.js-bindCertificateIssue':     'folders'
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

    if !_.isEmpty(@config)
      @wizardConfig = @config

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
      'shown.bs.modal':  @onShown
      'hidden.bs.modal': =>
        @el.remove()

    if @slide
      @showSlide(@slide)
    else
      @showDiscoverDetails()

    if @start
      @[@start]()

  render: =>
    @html App.view('integration/exchange_wizard')()

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
    @$('.js-discover input[name="user"]').val(@wizardConfig.user)
    @$('.js-discover input[name="password"]').val(@wizardConfig.password)

  showBindDetails: =>
    @$('.js-bind input[name="endpoint"]').val(@wizardConfig.endpoint)
    @$('.js-bind input[name="user"]').val(@wizardConfig.user)
    @$('.js-bind input[name="password"]').val(@wizardConfig.password)

  showSlideDiscover: =>
    @showSlide('js-discover')

  discover: (e) =>
    e.preventDefault()
    @showSlide('js-connect')
    params = @formParam(e.target)
    @ajax(
      id:   'exchange_discover'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/autodiscover"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result isnt 'ok'
          @handleCertificateIssue(
            message:     data.message
            wizardClass: 'js-discover'
            user:        params.user
            password:    params.password
          )
          return

        @wizardConfig.disable_ssl_verify = params.disable_ssl_verify
        @wizardConfig.user               = params.user
        @wizardConfig.password           = params.password

        @showSlide('js-bind')
        @showBindDetails()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-discover')
        @showAlert('js-discover', details.error || 'Unable to perform backend.')
    )

  folders: (e) =>
    e.preventDefault()
    @showSlide('js-analyze')
    params = @formParam(e.target)
    @ajax(
      id:   'exchange_folders'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/folders"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result isnt 'ok'
          @handleCertificateIssue(
            message:     data.message
            wizardClass: 'js-bind'
            endpoint:    params.endpoint
            user:        params.user
            password:    params.password
          )
          return

        @wizardConfig.disable_ssl_verify = params.disable_ssl_verify
        @wizardConfig.endpoint           = params.endpoint
        @wizardConfig.user               = params.user
        @wizardConfig.password           = params.password

        # update wizard data
        @wizardConfig.wizardData = {}
        @wizardConfig.wizardData.backend_folders = data.folders

        @foldersShow()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-bind')
        @showAlert('js-bind', details.error || 'Unable to perform backend.')
    )

  foldersShow: (alreadyShown) =>
    @showSlide('js-folders') if !alreadyShown
    @foldersSelect.html(@createColumnSelection('folders', @wizardConfig.wizardData.backend_folders, @wizardConfig.folders))

  createColumnSelection: (name, options, selected) ->
    return App.UiElement.column_select.render(
      name: name
      null: false
      nulloption: false
      options: options
      value: selected
      onChange: (val) =>
        if val && val.length > 0
          @foldersSelectSubmit.removeClass('is-disabled')
        else
          @foldersSelectSubmit.addClass('is-disabled')
    )

  handleCertificateIssue: (params) =>
    if params.message.indexOf('certificate') is -1
      @showSlide(params.wizardClass)
      @showAlert(params.wizardClass, params.message)
    else
      wizardClass = "#{params.wizardClass}CertificateIssue"

      domain = @domainFromMessageOrEmail(
        message: params.message
        user:    params.user
      )

      wizardSlide = App.view('integration/exchange_certificate_issue')(
        wizardClass: wizardClass
        endpoint:    params.endpoint
        user:        params.user
        password:    params.password
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
    emailDomain = params.user.match(/@(.*)$/)
    if emailDomain
      return emailDomain[1]

    # fallback to user - better than no value?!
    return user

  mapping: (e) =>
    e.preventDefault()
    @showSlide('js-analyze')
    params = @formParam(e.target)

    # folders might be a single selection so we
    # have to ensure that is an Array so the
    # backend and frontend can handle it properly
    if typeof params.folders is 'string'
      params.folders = [ params.folders ]

    # add login params
    params.endpoint = @wizardConfig.endpoint
    params.user     = @wizardConfig.user
    params.password = @wizardConfig.password

    @ajax(
      id:   'exchange_mapping'
      type: 'POST'
      url:  "#{@apiPath}/integration/exchange/mapping"
      data: JSON.stringify(params)
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
        @wizardConfig.folders                       = params.folders
        @wizardConfig.wizardData.backend_attributes = data.attributes

        @mappingShow()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-folders')
        @showAlert('js-folders', details.error || 'Unable to perform backend.')
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

App.Config.set(
  'IntegrationExchange'
  {
    name: 'Exchange'
    target: '#system/integration/exchange'
    description: 'Exchange integration for contacts management.'
    controller: Exchange
    state: State
    permission: ['admin.integration.exchange']
  }
  'NavBarIntegrations'
)
