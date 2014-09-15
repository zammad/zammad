class Index extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    callbackHeader = (header) ->
      attribute =
        name:       'switch_to'
        display:    'Switch to'
        translation: true
      header.push attribute
      header

    callbackAttributes = (value, object, attribute, header, refObject) ->
      value = ' '
      attribute.class  = 'glyphicon glyphicon-user'
      attribute.link   = '#'
      attribute.title  = App.i18n.translateInline('Switch to')
      value

    switchTo = (id,e) =>
      e.preventDefault()
      @disconnectClient()
      $('#app').hide().attr('style', 'display: none!important')
      App.Auth._logout()
      window.location = App.Config.get('api_path') + '/sessions/switch/' + id

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'User'
      defaultSortBy: 'login'
      ignoreObjectIDs: [1]
      pageData:
        title:     'Users'
        home:      'users'
        object:    'User'
        objects:   'Users'
        navupdate: '#users'
        notes: [
          'Users are for any person in the system. Agents (Owners, Resposbiles, ...) and Customers.'
        ]
        buttons: [
          { name: 'New User', 'data-type': 'new', class: 'primary' }
        ]
        tableExtend:
          callbackHeader:   callbackHeader
          callbackAttributes:
            switch_to: [
              callbackAttributes
            ]
          bindCol:
            switch_to:
              events:
                'click': switchTo
    )

App.Config.set( 'User', { prio: 1000, name: 'Users', parent: '#manage', target: '#manage/users', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
