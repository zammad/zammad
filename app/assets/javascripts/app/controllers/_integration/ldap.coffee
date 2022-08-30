class Ldap extends App.ControllerIntegrationBase
  featureIntegration: 'ldap_integration'
  featureName: __('LDAP')
  description: [
    [__('Use this switch to start synchronization of your ldap sources.')]
    [__('If a user is found in two (or more) configured LDAP sources, the last synchronisation will win.')]
    [__('In order to be able to influence the desired behaviour in this regard, you can influence the order of the LDAP sources via drag & drop.')]
  ]
  events:
    'change .js-switch input': 'switch'

  render: =>
    super

    @index.releaseController() if @index
    @index = new LdapSourceIndex(
      el: @$('.js-list')
      id: @id
      genericObject: 'LdapSource'
      defaultSortBy: 'prio'
      pageData:
        home: 'ldap'
        object: __('Source')
        objects: __('Sources')
        navupdate: '#system/integration/ldap'
        notes: []
        buttons: [
          { name: __('New Source'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
      dndCallback: (e, item) =>
        items = @$('.js-list').find('table > tbody > tr')
        prios = []
        prio = 0
        for item in items
          prio += 1
          id = $(item).data('id')
          prios.push [id, prio]

        @ajax(
          id:          'ldap_sources_prio'
          type:        'POST'
          url:         "#{@apiPath}/ldap_sources_prio"
          processData: true
          data:        JSON.stringify(prios: prios)
        )
      )

    @importResult.releaseController() if @importResult
    @importResult = new ImportResult(
      el: @$('.js-state')
    )

    @httpLog.releaseController() if @httpLog
    @httpLog = new App.HttpLog(
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

class ImportResult extends App.Controller
  elements:
    '.js-lastImport': 'lastImport'
  events:
    'click .js-start-sync': 'startSync'

  constructor: ->
    super
    @render()

  render: =>
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
            App.Event.trigger('LDAP::ImportJob::WizardState', !job.finished_at)
        @delay(@render, 5000, 'ImportResultRender')
    )

    if !@renderBind
      @renderBind = App.Event.bind('LDAP::ImportJob::Render', @render)
    if !@startSyncBind
      @startSyncBind = App.Event.bind('LDAP::ImportJob::StartSync', @startSync)

  lastResultShow: (job) =>
    if !job.result.roles
      job.result.roles = {}
    for role_id, statistic of job.result.role_ids
      if App.Role.exists(role_id)
        role = App.Role.find(role_id)
        job.result.roles[role.displayName()] = statistic

    @html App.view('integration/ldap_last_import')(job: job)

  startSync: =>
    @ajax(
      id:   'jobs_config'
      type: 'POST'
      url:  "#{@apiPath}/integration/ldap/job_start"
      processData: true
      success: (data, status, xhr) =>
        @render()
    )

class Form extends App.Controller
  elements:
    '.js-wizard': 'wizardButton'
  events:
    'click .js-wizard': 'startWizard'
    'click .js-back': 'showIndex'

  constructor: ->
    super

    @hideIndex()
    @render()

    App.Event.bind('LDAP::ImportJob::WizardState', (state) =>
      @wizardButton.attr('disabled', state)
    )
    App.Event.bind('LDAP::Form::Render', @render)

    App.Event.trigger('LDAP::ImportJob::Render')
    @activeDryRun()

  hideIndex: (e = undefined) =>
    @el.closest('.main').find('.page-content').children().each(->
      return true if $(@).hasClass('js-state')

      if $(@).hasClass('js-form')
        $(@).removeClass('hidden')
      else
        $(@).addClass('hidden')
    )

  showIndex: (e = undefined) ->
    if e
      e.preventDefault()

    @el.closest('.main').find('.page-content').children().each(->
      return true if $(@).hasClass('js-state')

      if $(@).hasClass('js-form')
        $(@).addClass('hidden')
      else
        $(@).removeClass('hidden')
    )

  currentConfig: ->
    config        = _.clone(@item.preferences)
    config.id     = @item.id
    config.name   = @item.name
    config.active = @item.active
    config

  setConfig: (value) =>
    @item.name = value.name
    @item.active = value.active
    @item.preferences = _.omit(value, ['id', 'name', 'active'])
    @item.save(
      done: =>
        @showIndex()
        App.Event.trigger('LDAP::ImportJob::StartSync')
        App.Event.trigger('LDAP::Form::Render')
    )

  render: (top = false) =>
    @config = @currentConfig()

    group_role_map = {}
    for source, dests of @config.group_role_map
      group_role_map[source] = dests.map((dest) ->
        return '?' if !App.Role.exists(dest)
        App.Role.find(dest).displayName()
      ).join ', '

    @html App.view('integration/ldap')(
      item: @item
      config: @config
      group_role_map: group_role_map
    )
    if _.isEmpty(@config.host_url)
      @$('.js-notConfigured').removeClass('hide')
      @$('.js-summary').addClass('hide')
    else
      @$('.js-notConfigured').addClass('hide')
      @$('.js-summary').removeClass('hide')

    if top
      a = =>
        @scrollToIfNeeded($('.content.active .page-header'))
      @delay(a, 500)

  startWizard: (e) =>
    e.preventDefault()
    new ConnectionWizard(
      container: @el.closest('.content')
      config: @config
      callback: (config) =>
        @setConfig(config)
    )

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
            App.Event.trigger('LDAP::ImportJob::WizardState', false)
            @setConfig(config)
        )
        App.Event.trigger('LDAP::ImportJob::WizardState', true)
    )

class State
  @current: ->
    App.Setting.get('ldap_integration')

class ConnectionWizard extends App.ControllerWizardModal
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
    'click .js-saveQuit':                'saveQuit'
    'input .js-hostUrl':                 'sslVerifyChange'

  elements:
    '.modal-body': 'body'
    '.js-userMappingForm': 'userMappingForm'
    '.js-groupRoleForm': 'groupRoleForm'
    '.js-expertForm': 'expertForm'

  constructor: ->
    super

    @wizardConfig = @config || {}
    @wizardData   = {}

    if @container
      @el.addClass('modal--local')

    @render()

    @el.modal
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    .on
      'shown.bs.modal': =>
        @el.addClass('modal--ready')
      'hidden.bs.modal': =>
        @el.remove()

    if @slide
      @showSlide(@slide)
    else
      @showHost()

    if @start
      @[@start]()

  render: =>
    nameHtml = App.UiElement.input.render({ name: 'name', display: __('Name'), tag: 'input', class: 'form-control--small', required: 'required', value: @config.name })[0].outerHTML
    activeHtml = App.UiElement.boolean.render({ name: 'active', display: __('Active'), tag: 'active', value: @config.active, required: 'required', class: 'form-control--small' })[0].outerHTML

    @html App.view('integration/ldap_wizard')(
      newConnection: @newConnection
      nameHtml: nameHtml
      activeHtml: activeHtml
    )

  saveQuit: (e) =>
    e.preventDefault()

    element = $(e.target).closest('form').get(0)
    return if element && element.reportValidity && !element.reportValidity()

    params                   = @formParam(e.target)
    @wizardConfig.host_url   = params.host_url
    @wizardConfig.ssl_verify = params.ssl_verify
    @wizardConfig.name       = params.name
    @wizardConfig.active     = params.active

    @callback(@wizardConfig)
    @hide(e)

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
      @$('.js-hostUrl').closest('tr').after(@buildRowSslVerify())

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

    element = $(e.target).closest('form').get(0)
    return if element && element.reportValidity && !element.reportValidity()

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
        @wizardConfig.name       = params.name
        @wizardConfig.active     = params.active

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
        @showAlert('js-discover', details.error || __('Server operation failed.'))
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
          @showAlert('js-bind', __('User information could not be retrieved, please check your bind user permissions.'))
          return

        if _.isEmpty(data.groups)
          @showSlide('js-bind')
          @showAlert('js-bind', __('Group information could not be retrieved, please check your bind user permissions.'))
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
        @wizardData = {}
        @wizardData.backend_user_attributes = data.user_attributes
        @wizardData.backend_groups = data.groups
        @wizardData.user_attributes = user_attributes
        @wizardData.roles = roles

        for key in ['user_uid', 'user_filter', 'group_uid', 'group_filter']
          @wizardConfig[key] ?= data[key]

        @mappingShow()

      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @showSlide('js-bind')
        @showAlert('js-bind', details.error || __('Server operation failed.'))
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
    el.find('.js-ldapAttribute').html(@createSelection('source', @wizardData.backend_user_attributes, source, true))
    el.find('.js-userAttribute').html(@createSelection('dest', @wizardData.user_attributes, dest))
    el

  buildRowsGroupRole: (group_role_map) =>
    el = []
    for source, dests of group_role_map
      for dest in dests
        el.push @buildRowGroupRole(source, dest)
    el

  buildRowGroupRole: (source, dest) =>
    el = $(App.view('integration/ldap_group_role_row')())
    el.find('.js-ldapList').html(@createAutocompletion('source', @wizardData.backend_groups, source))
    el.find('.js-roleList').html(@createSelection('dest', @wizardData.roles, dest))
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

  # LDAP with many groups (<5k) and group role relation (>50) will crash in frontend #3994
  createAutocompletion: (name, options, selected) ->
    return App.UiElement.autocompletion.render(
      id: "#{name}#{Math.floor( Math.random() * 999999 ).toString()}"
      name: name
      multiple: false
      null: false
      nulloption: false
      class: 'form-control--small'
      minLengt: -1 # show values without any value
      value: selected
      source: (request, response) ->
        data    = Object.keys(options)
        counter = 0
        total   = 200
        result  = []
        for entry in data
          continue if !entry.includes(request.term)
          break if counter >= total
          result.push(
            id: entry
            label: entry
            value: entry
          )
          counter++
        response(result)
    , "#{name}_autocompletion_value_shown": selected)

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


class LdapSourceIndex extends App.ControllerGenericIndex
  constructor: ->
    super
    App.Event.bind('LdapSource:destroy', (item) =>
      return if !@ldapForm
      return if item.id != @ldapForm.item.id

      @ldapForm.releaseController()
    )

  new: (e) ->
    e.preventDefault()

    new ConnectionWizard(
      container: @el.closest('.content')
      config: {}
      newConnection: true
      callback: (config) ->
        item = new App.LdapSource(
          name: config.name
          active: config.active
          preferences: _.omit(config, ['id', 'name', 'active'])
        )
        item.save(
          done: ->
            App.Event.trigger('LDAP::ImportJob::StartSync')
            App.Event.trigger('LDAP::Form::Render')
        )
    )

  edit: (id, e) =>
    e.preventDefault()
    item = App[ @genericObject ].find(id)

    @ldapForm.releaseController() if @ldapForm
    @ldapForm = new Form(
      el: @el.closest('.main').find('.js-form')
      item: item
    )

App.Config.set(
  'IntegrationLDAP'
  {
    name: __('LDAP')
    target: '#system/integration/ldap'
    description: __('LDAP integration for user management.')
    controller: Ldap
    state: State
    permission: ['admin.integration.ldap']
  }
  'NavBarIntegrations'
)
