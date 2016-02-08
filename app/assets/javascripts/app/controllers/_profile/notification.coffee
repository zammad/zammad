class Index extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    return if !@authenticate()
    @title 'Notifications', true
    @render()

  render: =>

    # matrix
    config =
      group_ids: []
      matrix:
        create:
          name: 'new Ticket'
        update:
          name: 'Ticket update'
        reminder_reached:
          name: 'Ticket reminder reached'
        escalation:
          name: 'Ticket escalation'

    user_config = @Session.get('preferences').notification_config
    if user_config
      config = $.extend(true, {}, config, user_config)

    # groups
    user_group_config = true
    if !user_config || !user_config['group_ids'] || _.isEmpty(user_config['group_ids']) || user_config['group_ids'][0] is '-'
      user_group_config = false

    groups = []
    group_ids = @Session.get('group_ids')
    if group_ids
      for group_id in group_ids
        group = App.Group.find(group_id)
        groups.push group
        if !user_group_config
          if !config['group_ids']
            config['group_ids'] = []
          config['group_ids'].push group_id.toString()

    @html App.view('profile/notification')( groups: groups, config: config )

  update: (e) =>

    #notification_config
    e.preventDefault()
    params = {}
    params.notification_config = {}

    form_params = @formParam(e.target)
    for key, value of form_params
      if key is 'group_ids'
        if typeof value isnt 'object'
          value = [value]
        params.notification_config[key] = value
      else
        area = key.split('.')
        if value is 'true'
          value = true
        if area[0] is 'matrix'
          if area[2] is 'criteria'
            if !params.notification_config[area[0]]
              params.notification_config[area[0]] = {}
            if !params.notification_config[area[0]][area[1]]
              params.notification_config[area[0]][area[1]] = {}
            if !params.notification_config[area[0]][area[1]][area[2]]
              params.notification_config[area[0]][area[1]][area[2]] = {
                owned_by_me:     false
                owned_by_nobody: false
                no:              false
              }
            params.notification_config[area[0]][area[1]][area[2]][area[3]] = value
          if area[2] is 'channel'
            if !params.notification_config[area[0]]
              params.notification_config[area[0]] = {}
            if !params.notification_config[area[0]][area[1]]
              params.notification_config[area[0]][area[1]] = {}
            if value is 'online'
              params.notification_config[area[0]][area[1]][area[2]] = {
                email:  false
                online: true
              }
            else
              params.notification_config[area[0]][area[1]][area[2]] = {
                email:  true
                online: false
              }
    if !params.notification_config.group_ids || _.isEmpty(params.notification_config.group_ids)
      params.notification_config.group_ids = ['-']
    @formDisable(e)

    # get data
    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         @apiPath + '/users/preferences'
      data:        JSON.stringify({user:params})
      processData: true
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    App.User.full(
      App.Session.get('id'),
      =>
        App.Event.trigger('ui:rerender')
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent('Successfully!')
        )
      ,
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set( 'Notifications', { prio: 2600, name: 'Notifications', parent: '#profile', target: '#profile/notifications', role: ['Agent'], controller: Index }, 'NavBarProfile' )
