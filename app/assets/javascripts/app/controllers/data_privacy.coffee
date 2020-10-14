class Index extends App.ControllerSubContent
  requiredPermission: 'admin.data_privacy'
  header: 'Data Privacy'
  events:
    'click .js-new':         'new'
    'click .js-description': 'description'
    'click .js-toggle-tickets': 'toggleTickets'

  constructor: ->
    super
    @load()
    @subscribeDataPrivacyTaskId = App.DataPrivacyTask.subscribe(@render)

  load: =>
    callback = =>
      @stopLoading()
      @render()
    @startLoading()
    App.DataPrivacyTask.fetchFull(
      callback
      clear: true
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    if params.integration

      # we reuse the integration parameter
      # because there is no own route possible
      # (see manage.coffee)
      @user_id = params.integration
      @navigate '#system/data_privacy'
      return

    if @user_id
      @new(false, @user_id)
      @user_id = undefined

  render: =>
    runningTasks = App.DataPrivacyTask.search(
      filter:
        state: 'in process'
      order:  'DESC'
    )
    runningTasksHTML = App.view('data_privacy/tasks')(
      tasks: runningTasks
    )

    failedTasks = App.DataPrivacyTask.search(
      filter:
        state: 'failed'
      order:  'DESC'
    )
    failedTasksHTML = App.view('data_privacy/tasks')(
      tasks: failedTasks
    )

    completedTasks = App.DataPrivacyTask.search(
      filter:
        state: 'completed'
      order:  'DESC'
    )
    completedTasksHTML = App.view('data_privacy/tasks')(
      tasks: completedTasks
    )

    # show description button, only if content exists
    description = marked(App.i18n.translateContent(App.DataPrivacyTask.description))

    @html App.view('data_privacy/index')(
      taskCount: ( runningTasks.length + failedTasks.length + completedTasks.length )
      runningTaskCount: runningTasks.length
      failedTaskCount: failedTasks.length
      completedTaskCount: completedTasks.length
      runningTasksHTML: runningTasksHTML
      failedTasksHTML: failedTasksHTML
      completedTasksHTML: completedTasksHTML
      description: description
    )

  release: =>
    if @subscribeDataPrivacyTaskId
      App.DataPrivacyTask.unsubscribe(@subscribeDataPrivacyTaskId)

  new: (e, user_id = undefined) ->
    if e
      e.preventDefault()

    new TaskNew(
      pageData:
        head: 'Deletion Task'
        title: 'Deletion Task'
        object: 'DataPrivacyTask'
        objects: 'DataPrivacyTasks'
      genericObject: 'DataPrivacyTask'
      container:     @el.closest('.content')
      callback:      @load
      large:         true
      handlers: [@formHandler]
      item:
        'deletable_id': user_id
    )

  toggleTickets: (e) ->
    e.preventDefault()

    id       = $(e.target).data('id')
    type     = $(e.target).data('type')
    expanded = $(e.target).hasClass('expanded')
    return if !id

    new_expanded = ''
    text         = 'See more'
    if !expanded
      new_expanded = ' expanded'
      text         = 'See less'

    task = App.DataPrivacyTask.find(id)

    list = clone(task.preferences[type])
    if expanded
      list = list.slice(0, 50)
      list.push('...')
    list = list.join(', ')

    $(e.target).closest('div.ticket-list').html(list + ' <br><div class="btn btn--text js-toggle-tickets' + new_expanded + '" data-type="' + type + '" data-id="' + id + '">' + App.i18n.translateInline(text) + '</div>')

  description: (e) =>
    new App.ControllerGenericDescription(
      description: App.DataPrivacyTask.description
      container:   @el.closest('.content')
    )

  formHandler: (params, attribute, attributes, classname, form, ui) ->
    return if !attribute

    userID = params['deletable_id']
    if userID
      $('body').find('.js-TaskNew').removeClass('hidden')
    else
      $('body').find('.js-TaskNew').addClass('hidden')
      form.find('.js-preview').remove()

    return if !userID

    conditionCustomer =
      'condition':
        'ticket.customer_id':
          'operator': 'is'
          'pre_condition':'specific'
          'value': userID

    conditionOwner =
      'condition':
        'ticket.owner_id':
          'operator': 'is'
          'pre_condition':'specific'
          'value': userID

    App.Ajax.request(
      id:    'ticket_selector'
      type:  'POST'
      url:   "#{App.Config.get('api_path')}/tickets/selector"
      data:        JSON.stringify(conditionCustomer)
      processData: true,
      success: (dataCustomer, status, xhr) ->
        App.Collection.loadAssets(dataCustomer.assets)

        App.Ajax.request(
          id:    'ticket_selector'
          type:  'POST'
          url:   "#{App.Config.get('api_path')}/tickets/selector"
          data:        JSON.stringify(conditionOwner)
          processData: true,
          success: (dataOwner, status, xhr) ->
            App.Collection.loadAssets(dataOwner.assets)

            user               = App.User.find(userID)
            deleteOrganization = ''
            if user.organization_id
              organization = App.Organization.find(user.organization_id)
              if organization && organization.member_ids.length < 2
                attribute          = { name: 'preferences::delete_organization',  display: 'Delete organization?', tag: 'boolean', default: true, translate: true }
                deleteOrganization = ui.formGenItem(attribute, classname, form).html()

            sure_attribute = { name: 'preferences::sure',  display: 'Are you sure?', tag: 'input', translate: false, placeholder: App.i18n.translateInline('delete').toUpperCase() }
            sureInput      = ui.formGenItem(sure_attribute, classname, form).html()

            preview_html = App.view('data_privacy/preview')(
              customer_count:           dataCustomer.ticket_count || 0
              owner_count:              dataOwner.ticket_count    || 0
              delete_organization_html: deleteOrganization
              sure_html:                sureInput
              user_id:                  userID
            )

            if form.find('.js-preview').length < 1
              form.append(preview_html)
            else
              form.find('.js-preview').replaceWith(preview_html)

            new App.TicketList(
              tableId:    'ticket-selector'
              el:         form.find('.js-previewTableCustomer')
              ticket_ids: dataCustomer.ticket_ids
            )
            new App.TicketList(
              tableId:    'ticket-selector'
              el:         form.find('.js-previewTableOwner')
              ticket_ids: dataOwner.ticket_ids
            )
        )
    )

class TaskNew extends App.ControllerGenericNew
  buttonSubmit: 'Delete'
  buttonClass: 'btn--danger js-TaskNew hidden'

  content: ->
    if @item['deletable_id']
      @buttonClass = 'btn--danger js-TaskNew'
    else
      @buttonClass = 'btn--danger js-TaskNew hidden'

    super

  onSubmit: (e) ->
    params = @formParam(e.target)
    params['deletable_type'] = 'User'

    object = new App[ @genericObject ]
    object.load(params)

    # validate
    errors = object.validate()
    if params['preferences']['sure'] isnt App.i18n.translateInline('delete').toUpperCase()
      if !errors
        errors = {}
      errors['preferences::sure'] = 'invalid'

    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # disable form
    @formDisable(e)

    # save object
    ui = @
    object.save(
      done: ->
        if ui.callback
          item = App[ ui.genericObject ].fullLocal(@id)
          ui.callback(item)
        ui.close()

      fail: (settings, details) ->
        ui.log 'errors', details
        ui.formEnable(e)
        ui.controller.showAlert(details.error_human || details.error || 'Unable to create object!')
    )

App.Config.set('DataPrivacy', { prio: 3600, name: 'Data Privacy', parent: '#system', target: '#system/data_privacy', controller: Index, permission: ['admin.data_privacy'] }, 'NavBarAdmin')
