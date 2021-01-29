class Ldap extends App.ControllerIntegrationBase
  featureIntegration: 'ldap_integration'
  featureName: 'LDAP'
  featureConfig: 'ldap_config'
  description: [
    ['This service enables Zammad to connect with your LDAP server.']
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
    #  facility: 'ldap'
    #)

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'ldap'
    )

  switch: =>
    super
    active = @$('.js-switch input').prop('checked')
    if active
      job_start = =>
        @ajax(
          id:   'jobs_config'
          type: 'POST'
          url:  "#{@apiPath}/integration/ldap/job_start"
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
    App.Setting.get('ldap_config') || {}

  setConfig: (value) =>
    App.Setting.set('ldap_config', value, {notify: true})
    @startSync()

  render: (top = false) =>
    @config = @currentConfig()

    group_role_map = {}
    for source, dests of @config.group_role_map
      group_role_map[source] = dests.map((dest) ->
        return '?' if !App.Role.exists(dest)
        App.Role.find(dest).displayName()
      ).join ', '

    @html App.view('integration/ldap')(
      config: @config,
      group_role_map: group_role_map
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
      url:  "#{@apiPath}/integration/ldap/job_start"
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
      url:  "#{@apiPath}/integration/ldap/job_start"
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
      if App.Role.exists(role_id)
        role = App.Role.find(role_id)
        job.result.roles[role.displayName()] = statistic
    el = $(App.view('integration/ldap_last_import')(job: job))
    @lastImport.html(el)

  activeDryRun: =>
    @ajax(
      id:   'jobs_try_index'
      type: 'GET'
      url:  "#{@apiPath}/integration/ldap/job_try"
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
    App.Setting.get('ldap_integration')

class ConnectionWizard extends App.ControllerWizardModal
  wizardConfig: {}
  slideMethod:
    'js-bind': 'bindShow'
    'js-mapping': 'mappingShow'

  events:
    'submit form.js-discover':           'discover'
    'submit form.js-bind':               'bindChange'
    'click .js-mapping .js-submitTry':   'mappingChange'
    'click .js-try .js-submitSave':      'save'
    'click .js-close':                   'hide'
    'click .js-remove':                  'removeRow'
    'click .js-userMappingForm .js-add': 'addUserMapping'
    'click .js-groupRoleForm .js-add':   'addGroupRoleMapping'
    'click .js-goToSlide':               'goToSlide'
    'input .js-hostUrl':                 'sslVerifyChange'

  elements:
    '.modal-body': 'body'
    '.js-userMappingForm': 'userMappingForm'
    '.js-groupRoleForm': 'groupRoleForm'
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
      @showHost()

    if @start
      @[@start]()

  render: =>
    @html App.view('integration/ldap_wizard')()

  save: (e) =>
    e.preventDefault()
    @callback(@wizardConfig)
    @hide(e)

  showSlide: (slide) =>
    method = @slideMethod[slide]
    if method && @[method]
      @[method](true)
    super

  showHost: =>
    @$('.js-discover input[name="host_url"]').val(@wizardConfig.host_url)
    @checkSslVerifyVisibility(@wizardConfig.host_url)

  sslVerifyChange: (e) =>
    @checkSslVerifyVisibility($(e.currentTarget).val())

  checkSslVerifyVisibility: (host_url) =>
    el     = @$('.js-discover .js-sslVerify')
    exists = el.length

    disabled = true
    if host_url && host_url.startsWith('ldaps')
      disabled = false

    if exists && disabled
      el.parent().remove()
    else if !exists && !disabled
      @$('.js-discover tbody tr').last().after(@buildRowSslVerify())

  buildRowSslVerify: =>
    el = $(App.view('integration/ldap_ssl_verify_row')())

    ssl_verify = true
    if typeof @wizardConfig.ssl_verify != 'undefined'
      ssl_verify = @wizardConfig.ssl_verify

    sslVerifyElement = App.UiElement.boolean.render(
      name: 'ssl_verify'
      null: false
      options: { true: 'yes', false: 'no' }
      default: ssl_verify
      translate: true
      class: 'form-control form-control--small'
    )
    el.find('.js-sslVerify').html sslVerifyElement
    el

  discover: (e) =>
    e.preventDefault()
    @showSlide('js-connect')
    params = @formParam(e.target)
    @ajax(
      id:   'ldap_discover'
      type: 'POST'
      url:  "#{@apiPath}/integration/ldap/discover"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result isnt 'ok'
          @showSlide('js-discover')
          @showAlert('js-discover', data.message)
          return

        @wizardConfig.host_url   = params.host_url
        @wizardConfig.ssl_verify = params.ssl_verify

        option = ''
        options = {}
        if !_.isEmpty(data.attributes) && !_.isEmpty(data.attributes.namingcontexts)
          for dn in data.attributes.namingcontexts
            options[dn] = dn
            if option is ''
              option = dn
            if option.length > dn.length
              option = dn

        @wizardConfig.options = options
        @wizardConfig.option = option

        @bindShow()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-discover')
        @showAlert('js-discover', details.error || 'Unable to perform backend.')
    )


  bindShow: (alreadyShown) =>
    @showSlide('js-bind') if !alreadyShown
    @$('.js-bind .js-baseDn').html(@createSelection('base_dn', @wizardConfig.options, @wizardConfig.base_dn || @wizardConfig.option, true))
    @$('.js-bind input[name="bind_user"]').val(@wizardConfig.bind_user)
    @$('.js-bind input[name="bind_pw"]').val(@wizardConfig.bind_pw)

  bindChange: (e) =>
    e.preventDefault()
    @showSlide('js-analyze')
    params            = @formParam(e.target)
    params.host_url   = @wizardConfig.host_url
    params.ssl_verify = @wizardConfig.ssl_verify
    @ajax(
      id:   'ldap_bind'
      type: 'POST'
      url:  "#{@apiPath}/integration/ldap/bind"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result isnt 'ok'
          @showSlide('js-bind')
          @showAlert('js-bind', data.message)
          return

        if _.isEmpty(data.user_attributes)
          @showSlide('js-bind')
          @showAlert('js-bind', 'Unable to retrive user information, please check your bind user permissions.')
          return

        if _.isEmpty(data.groups)
          @showSlide('js-bind')
          @showAlert('js-bind', 'Unable to retrive group information, please check your bind user permissions.')
          return

        # update config if successful
        for key, value of params
          @wizardConfig[key] = value

        # remember payload
        user_attributes = {}
        for key, value of App.User.attributesGet()
          if (value.tag is 'input' || value.tag is 'richtext' || value.tag is 'textarea')  && value.type isnt 'password'
            user_attributes[key] = value.display || key
        roles = {}
        for role in App.Role.findAllByAttribute('active', true)
          roles[role.id] = role.displayName()

        # update wizard data
        @wizardConfig.wizardData= {}
        @wizardConfig.wizardData.backend_user_attributes = data.user_attributes
        @wizardConfig.wizardData.backend_groups = data.groups
        @wizardConfig.wizardData.user_attributes = user_attributes
        @wizardConfig.wizardData.roles = roles

        for key in ['user_uid', 'user_filter', 'group_uid', 'group_filter']
          @wizardConfig[key] ?= data[key]

        @mappingShow()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-bind')
        @showAlert('js-bind', details.error || 'Unable to perform backend.')
    )

  mappingShow: (alreadyShown) =>
    @showSlide('js-mapping') if !alreadyShown
    user_attribute_map = @wizardConfig.user_attributes
    if _.isEmpty(user_attribute_map)
      user_attribute_map =
        givenname: 'firstname'
        sn: 'lastname'
        mail: 'email'
        samaccountname: 'login'
        telephonenumber: 'phone'

    @userMappingForm.find('tbody tr.js-entry').remove()
    @userMappingForm.find('tbody tr').before(@buildRowsUserMap(user_attribute_map))
    @groupRoleForm.find('tbody tr.js-entry').remove()
    @groupRoleForm.find('tbody tr').before(@buildRowsGroupRole(@wizardConfig.group_role_map))

    @$('.js-mapping input[name="user_filter"]').val(@wizardConfig.user_filter)

    unassigned_users_choices =
      sigup_roles: App.i18n.translatePlain('Assign signup roles')
      skip_sync: App.i18n.translatePlain('Don\'t synchronize')

    @$('.js-unassignedUsers').html(@createSelection('unassigned_users', unassigned_users_choices, @wizardConfig.unassigned_users || 'sigup_roles'))

  mappingChange: (e) =>
    e.preventDefault()

    # user map
    user_attributes = @formParam(@userMappingForm)
    for key in ['source', 'dest']
      if !_.isArray(user_attributes[key])
        user_attributes[key] = [user_attributes[key]]
    user_attributes_local = {}
    length = user_attributes.source.length-1
    for count in [0..length]
      if user_attributes.source[count] && user_attributes.dest[count]
        user_attributes_local[user_attributes.source[count]] = user_attributes.dest[count]

    requiredAttribute = Object.keys(user_attributes_local).some( (local_attribute) ->
      return user_attributes_local[local_attribute] == 'login'
    )

    @wizardConfig.user_attributes = user_attributes_local

    if !requiredAttribute
      @showSlide('js-mapping')
      @showAlert('js-mapping', App.i18n.translatePlain("Attribute '%s' is required in the mapping", 'login'))
      return

    # group role map
    group_role_map = @formParam(@groupRoleForm)
    for key in ['source', 'dest']
      if !_.isArray(group_role_map[key])
        group_role_map[key] = [group_role_map[key]]
    group_role_map_local = {}
    length = group_role_map.source.length-1
    for count in [0..length]
      if group_role_map.source[count] && group_role_map.dest[count]
        if !_.isArray(group_role_map_local[group_role_map.source[count]])
          group_role_map_local[group_role_map.source[count]] = []
        group_role_map_local[group_role_map.source[count]].push group_role_map.dest[count]
    @wizardConfig.group_role_map = group_role_map_local

    expertSettings = @formParam(@expertForm)

    @wizardConfig.user_filter      = expertSettings.user_filter
    @wizardConfig.unassigned_users = expertSettings.unassigned_users

    @tryShow()

  buildRowsUserMap: (user_attribute_map) =>

    el = []
    for source, dest of user_attribute_map
      el.push @buildRowUserAttribute(source, dest)
    el

  buildRowUserAttribute: (source, dest) =>
    el = $(App.view('integration/ldap_user_attribute_row')())
    el.find('.js-ldapAttribute').html(@createSelection('source', @wizardConfig.wizardData.backend_user_attributes, source, true))
    el.find('.js-userAttribute').html(@createSelection('dest', @wizardConfig.wizardData.user_attributes, dest))
    el

  buildRowsGroupRole: (group_role_map) =>
    el = []
    for source, dests of group_role_map
      for dest in dests
        el.push @buildRowGroupRole(source, dest)
    el

  buildRowGroupRole: (source, dest) =>
    el = $(App.view('integration/ldap_group_role_row')())
    el.find('.js-ldapList').html(@createSelection('source', @wizardConfig.wizardData.backend_groups, source))
    el.find('.js-roleList').html(@createSelection('dest', @wizardConfig.wizardData.roles, dest))
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

  addGroupRoleMapping: (e) =>
    e.preventDefault()
    @groupRoleForm.find('tbody tr').last().before(@buildRowGroupRole())

  tryShow: (e) =>
    if e
      e.preventDefault()
    @showSlide('js-analyze')

    # create import job
    @ajax(
      id:   'ldap_try'
      type: 'POST'
      url:  "#{@apiPath}/integration/ldap/job_try"
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
      url:  "#{@apiPath}/integration/ldap/job_try"
      data:
        finished: true
      processData: true
      success: (job, status, xhr) =>
        if job.result && (job.result.error || job.result.info)
          @showSlide('js-error')
          @showAlert('js-error', (job.result.error || job.result.info))
          return

        if job.result && job.result.total
          @$('.js-preprogress').addClass('hide')
          @$('.js-analyzing').removeClass('hide')

          @$('.js-progress progress').attr('value', job.result.sum)
          @$('.js-progress progress').attr('max', job.result.total)
        if job.finished_at
          # reset initial state in case the back button is used
          @$('.js-preprogress').removeClass('hide')
          @$('.js-analyzing').addClass('hide')

          @tryResult(job)
          return
        else
          @delay(@tryLoop, 4000)
          return
        @hide()
    )

  tryResult: (job) =>
    if !job.result.roles
      job.result.roles = {}
    for role_id, statistic of job.result.role_ids
      if App.Role.find(role_id)
        role = App.Role.find(role_id)
        job.result.roles[role.displayName()] = statistic
    @showSlide('js-try')
    el = $(App.view('integration/ldap_summary')(job: job))
    @el.find('.js-summary').html(el)

App.Config.set(
  'IntegrationLDAP'
  {
    name: 'LDAP'
    target: '#system/integration/ldap'
    description: 'LDAP integration for user management.'
    controller: Ldap
    state: State
    permission: ['admin.integration.ldap']
  }
  'NavBarIntegrations'
)
