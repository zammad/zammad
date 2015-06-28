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
    config = {}
    config['matrix'] = {}
    config['matrix']['create'] = {}
    config['matrix']['create']['name'] = 'new Ticket'
    config['matrix']['create']['criteria'] = {}
    config['matrix']['create']['criteria']['owned_by_me'] = true
    config['matrix']['create']['criteria']['owned_by_nobody'] = true
    config['matrix']['create']['criteria']['no'] = false
    config['matrix']['create']['channel'] = {}
    config['matrix']['create']['channel']['email'] = true
    config['matrix']['create']['channel']['online'] = false
    config['matrix']['update'] = {}
    config['matrix']['update']['name'] = 'Ticket update'
    config['matrix']['update']['criteria'] = {}
    config['matrix']['update']['criteria']['owned_by_me'] = true
    config['matrix']['update']['criteria']['owned_by_nobody'] = false
    config['matrix']['update']['criteria']['no'] = false
    config['matrix']['update']['channel'] = {}
    config['matrix']['update']['channel']['email'] = true
    config['matrix']['update']['channel']['online'] = false
    config['matrix']['move_into'] = {}
    config['matrix']['move_into']['name'] = 'Ticket moved into my group'
    config['matrix']['move_into']['criteria'] = {}
    config['matrix']['move_into']['criteria']['owned_by_me'] = true
    config['matrix']['move_into']['criteria']['owned_by_nobody'] = true
    config['matrix']['move_into']['criteria']['no'] = false
    config['matrix']['move_into']['channel'] = {}
    config['matrix']['move_into']['channel']['email'] = true
    config['matrix']['move_into']['channel']['online'] = false
    config['matrix']['escalation'] = {}
    config['matrix']['escalation']['name'] = 'Ticket escalation'
    config['matrix']['escalation']['criteria'] = {}
    config['matrix']['escalation']['criteria']['owned_by_me'] = true
    config['matrix']['escalation']['criteria']['owned_by_nobody'] = true
    config['matrix']['escalation']['criteria']['no'] = false
    config['matrix']['escalation']['channel'] = {}
    config['matrix']['escalation']['channel']['email'] = true
    config['matrix']['escalation']['channel']['online'] = false

    user_config = @Session.get('preferences').notification_config
    if user_config
      config = $.extend(true, {}, config, user_config)
    console.log('oo', config)
    # groups
    groups = []
    group_ids = @Session.get('group_ids')
    if group_ids
      for group_id in group_ids
        group = App.Group.find(group_id)
        groups.push group

    @html App.view('profile/notification')( groups: groups, config: config )

  update: (e) =>

    #notification_config
    e.preventDefault()
    params = {}
    params.notification_config = {}

    form_params = @formParam(e.target)
    console.log('P',form_params)
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
    console.log('P2',params)

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
      App.Session.get( 'id' ),
      =>
        App.Event.trigger( 'ui:rerender' )
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent( 'Successfully!' )
        )
      ,
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse( xhr.responseText )
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent( data.message )
    )

App.Config.set( 'Notifications', { prio: 2600, name: 'Notifications', parent: '#profile', target: '#profile/notifications', role: ['Agent'], controller: Index }, 'NavBarProfile' )