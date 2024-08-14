class ProfileNotification extends App.ControllerSubContent
  @include App.TicketNotificationMatrix

  @requiredPermission: 'user_preferences.notifications+ticket.agent'
  header: __('Notifications')
  events:
    'submit form':                  'update'
    'click .js-reset' :             'reset'
    'change .js-notificationSound': 'previewSound'
    'change #profile-groups-limit': 'didSwitchGroupsLimit'
    'change input[name=group_ids]': 'didChangeGroupIds'

  elements:
    '#profile-groups-limit':                'profileGroupsLimitInput'
    '.profile-groups-limit-settings-inner': 'groupsLimitSettings'
    '.profile-groups-all-unchecked':        'groupsAllUncheckedWarning'

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
    App.User.full(App.Session.get().id, @render, true, true)

  render: =>

    matrix =
      create:
        name: __('New Ticket')
      update:
        name: __('Ticket update')
      reminder_reached:
        name: __('Ticket reminder reached')
      escalation:
        name: __('Ticket escalation')

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
      matrixTableHTML: @renderNotificationMatrix(config.matrix)
      groups: groups
      config: config
      sounds: @sounds
      notificationSoundEnabled: App.OnlineNotification.soundEnabled()
      user_group_config:        user_group_config

  update: (e) =>

    #notification_config
    e.preventDefault()
    params = {}
    params.notification_config = {}

    formParams = @formParam(e.target)

    params.notification_config.matrix = @updatedNotificationMatrixValues(formParams)

    if @profileGroupsLimitInput.is(':checked')
      params.notification_config.group_ids = formParams['group_ids']
      if typeof params.notification_config.group_ids isnt 'object'
        params.notification_config.group_ids = [params.notification_config.group_ids]

      if _.isEmpty(params.notification_config.group_ids)
        delete params.notification_config.group_ids

    @formDisable(e)

    params.notification_sound = formParams.notification_sound
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

  reset: (e) =>
    new App.ControllerConfirm(
      message:     __('Are you sure? Your notifications settings will be reset to default.')
      buttonClass: 'btn--danger'
      callback: =>
        @ajax(
          id:          'preferences_notifications_reset'
          type:        'POST'
          url:         "#{@apiPath}/users/preferences_notifications_reset"
          processData: true
          success:     @success
        )
      container: @el.closest('.content')
    )


  success: (data, status, xhr) =>
    App.User.full(
      App.Session.get('id'),
      =>
        App.Event.trigger('ui:rerender')
        @notify(
          type: 'success'
          msg:  __('Update successful.')
        )
      ,
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  data.message
    )

  previewSound: (e) =>
    params = @formParam(e.target)
    return if !params.notification_sound
    return if !params.notification_sound.file
    App.OnlineNotification.play(params.notification_sound.file)

  didSwitchGroupsLimit: (e) =>
    @groupsLimitSettings.collapse('toggle')

  didChangeGroupIds: (e) =>
    @groupsAllUncheckedWarning.toggleClass 'hide', @el.find('input[name=group_ids]:checked').length != 0

App.Config.set('Notifications', { prio: 2600, name: __('Notifications'), parent: '#profile', target: '#profile/notifications', permission: ['user_preferences.notifications+ticket.agent'], controller: ProfileNotification }, 'NavBarProfile')
