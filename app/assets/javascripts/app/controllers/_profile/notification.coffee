class ProfileNotification extends App.ControllerSubContent
  requiredPermission: 'user_preferences.notifications+ticket.agent'
  header: 'Notifications'
  events:
    'submit form': 'update'
    'change .js-notificationSound': 'previewSound'

  sounds: [
    {
      name: 'Bell'
      file: 'Bell.mp3'
    },
    {
      name: 'Kalimba'
      file: 'Kalimba.mp3'
    },
    {
      name: 'Marimba'
      file: 'Marimba.mp3'
    },
    {
      name: 'Peep'
      file: 'Peep.mp3'
    },
    {
      name: 'Plop'
      file: 'Plop.mp3'
    },
    {
      name: 'Ring'
      file: 'Ring.mp3'
    },
    {
      name: 'Space'
      file: 'Space.mp3'
    },
    {
      name: 'Wood'
      file: 'Wood.mp3'
    },
    {
      name: 'Xylo'
      file: 'Xylo.mp3'
    }
  ]

  constructor: ->
    super
    @render()

  render: =>

    matrix =
      create:
        name: 'New Ticket'
      update:
        name: 'Ticket update'
      reminder_reached:
        name: 'Ticket reminder reached'
      escalation:
        name: 'Ticket escalation'

    config =
      group_ids: []
      matrix: {}

    user_config = @Session.get('preferences').notification_config
    if user_config
      config = $.extend(true, {}, config, user_config)

    # groups
    user_group_config = true
    if !user_config || !user_config['group_ids'] || _.isEmpty(user_config['group_ids']) || user_config['group_ids'][0] is '-'
      user_group_config = false

    groups = []
    group_ids = App.User.find(@Session.get('id')).allGroupIds()
    if group_ids
      for group_id in group_ids
        group = App.Group.find(group_id)
        groups.push group
        if !user_group_config
          if !config['group_ids']
            config['group_ids'] = []
          config['group_ids'].push group_id.toString()

    groups = _.sortBy(groups, (item) -> return item.name)

    for sound in @sounds
      sound.selected = sound.file is App.OnlineNotification.soundFile() ? true : false

    @html App.view('profile/notification')
      matrix: matrix
      groups: groups
      config: config
      sounds: @sounds
      notificationSoundEnabled: App.OnlineNotification.soundEnabled()

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
              params.notification_config[area[0]][area[1]][area[2]] = {}

            for recipientKey in ['owned_by_me', 'owned_by_nobody', 'subscribed', 'no']
              if params.notification_config[area[0]][area[1]][area[2]][recipientKey] == undefined
                params.notification_config[area[0]][area[1]][area[2]][recipientKey] = false

            params.notification_config[area[0]][area[1]][area[2]][area[3]] = value
          if area[2] is 'channel'
            if !params.notification_config[area[0]]
              params.notification_config[area[0]] = {}
            if !params.notification_config[area[0]][area[1]]
              params.notification_config[area[0]][area[1]] = {}
            if value is 'email'
              params.notification_config[area[0]][area[1]][area[2]] = {
                email:  true
                online: true
              }

    # check missing channels
    if params['notification_config']
      for key, value of params['notification_config']['matrix']
        if !value.channel
          value.channel = {
            email:  false
            online: true
          }

    if !params.notification_config.group_ids || _.isEmpty(params.notification_config.group_ids)
      params.notification_config.group_ids = ['-']
    @formDisable(e)

    params.notification_sound = form_params.notification_sound
    if !params.notification_sound.enabled
      params.notification_sound.enabled = false
    else
      params.notification_sound.enabled = true

    # get data
    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         @apiPath + '/users/preferences'
      data:        JSON.stringify(params)
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
          msg:  App.i18n.translateContent('Successful!')
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

  previewSound: (e) =>
    params = @formParam(e.target)
    return if !params.notification_sound
    return if !params.notification_sound.file
    App.OnlineNotification.play(params.notification_sound.file)

App.Config.set('Notifications', { prio: 2600, name: 'Notifications', parent: '#profile', target: '#profile/notifications', permission: ['user_preferences.notifications+ticket.agent'], controller: ProfileNotification }, 'NavBarProfile')
