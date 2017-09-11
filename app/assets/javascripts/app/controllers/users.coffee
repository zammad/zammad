class Index extends App.ControllerSubContent
  requiredPermission: 'admin.user'
  header: 'Users'
  elements:
    '.js-search': 'searchInput'
  events:
    'click [data-type=new]': 'new'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('user')(
      head: 'Users'
      buttons: [
        { name: 'New User', 'data-type': 'new', class: 'btn--success' }
      ]
      roles: App.Role.all()
    )

    @$('.tab').on(
      'click'
      (e) =>
        e.preventDefault()
        $(e.target).toggleClass('active')
        query = @searchInput.val().trim()
        if query
          @delay( @search, 220, 'search' )
          return
        @recent()
    )

    # start search
    @searchInput.bind( 'keyup', (e) =>
      query = @searchInput.val().trim()
      return if !query
      return if query is @query
      @query = query
      @delay( @search, 220, 'search' )
    )

    # show last 20 users
    @recent()

  renderResult: (user_ids = []) ->
    @stopLoading()

    callbackHeader = (header) ->
      attribute =
        name:       'switch_to'
        display:    'Action'
        className:  'actionCell'
        translation: true
        width: '200px'
      header.push attribute
      header

    callbackAttributes = (value, object, attribute, header) ->
      text                  = App.i18n.translateInline('View from user\'s perspective')
      value                 = ' '
      attribute.raw         = ' <span class="btn btn--primary btn--table switchView" title="' + text + '">' + App.Utils.icon('switchView') + text + '</span>'
      attribute.class       = ''
      attribute.parentClass = 'actionCell no-padding'
      attribute.link        = ''
      attribute.title       = App.i18n.translateInline('Switch to')
      value

    switchTo = (id,e) =>
      e.preventDefault()
      e.stopPropagation()
      @disconnectClient()
      $('#app').hide().attr('style', 'display: none!important')
      @delay(
        =>
          App.Auth._logout(false)
          @ajax(
            id:          'user_switch'
            type:        'GET'
            url:         "#{@apiPath}/sessions/switch/#{id}"
            success:     (data, status, xhr) =>
              location = "#{window.location.protocol}//#{window.location.host}#{data.location}"
              @windowReload(undefined, location)
          )
        800
      )

    edit = (id, e) =>
      e.preventDefault()
      item = App.User.find(id)

      rerender = =>
        @renderResult(user_ids)

      new App.ControllerGenericEdit(
        id: item.id
        pageData:
          title:     'Users'
          home:      'users'
          object:    'User'
          objects:   'Users'
          navupdate: '#users'
        genericObject: 'User'
        callback: rerender
        container: @el.closest('.content')
      )

    users = []
    for user_id in user_ids
      user = App.User.find(user_id)
      users.push user

    @$('.table-overview').html('')
    new App.ControllerTable(
      tableId: 'users_admin_overview'
      el:      @$('.table-overview')
      model:   App.User
      objects: users
      class:   'user-list'
      callbackHeader: [callbackHeader]
      callbackAttributes:
        switch_to: [
          callbackAttributes
        ]
      bindCol:
        switch_to:
          events:
            'click': switchTo
      bindRow:
        events:
          'click': edit
    )

  search: =>
    role_ids = []
    @$('.tab.active').each( (i,d) ->
      role_ids.push $(d).data('id')
    )
    @startLoading(@$('.table-overview'))
    App.Ajax.request(
      id: 'search'
      type: 'GET'
      url: "#{@apiPath}/users/search"
      data:
        query: @query
        limit: 140
        role_ids: role_ids
        full:  1
      processData: true,
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @renderResult(data.user_ids)
      done: =>
        @stopLoading()
    )

  recent: =>
    role_ids = []
    @$('.tab.active').each( (i,d) ->
      role_ids.push $(d).data('id')
    )
    @startLoading(@$('.table-overview'))
    App.Ajax.request(
      id: 'search'
      type: 'GET'
      url: "#{@apiPath}/users/recent"
      data:
        limit: 50
        role_ids: role_ids
        full: 1
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @renderResult(data.user_ids)
        @stopLoading()
      error: =>
        @stopLoading()
    )

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        title:     'Users'
        home:      'users'
        object:    'User'
        objects:   'Users'
        navupdate: '#users'
      genericObject: 'User'
      container: @el.closest('.content')
      callback: @recent
    )

App.Config.set( 'User', { prio: 1000, name: 'Users', parent: '#manage', target: '#manage/users', controller: Index, permission: ['admin.user'] }, 'NavBarAdmin' )
