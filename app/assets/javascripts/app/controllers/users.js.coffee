class Index extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

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
#          { name: 'List', 'data-type': '', class: 'active' },
          { name: 'New User', 'data-type': 'new', class: 'primary' }
        ]
        addCol:
          overview: ['switch_to']
          attributes: [
            {
              name:     'switch_to'
              display:  'Switch to'
              type:     'link'
              class:    'glyphicon glyphicon-user'
              readonly: 1
              dataType: 'switch_to'
              callback: (e) ->
                e.preventDefault()
                user_id = $(e.target).parent().parent().data('id')
                App.Auth._logout()
                window.location = App.Config.get('api_path') + '/sessions/switch/' + user_id
            }
          ]
    )

App.Config.set( 'User', { prio: 1000, name: 'Users', parent: '#manage', target: '#manage/users', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
