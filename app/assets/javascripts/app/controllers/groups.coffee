class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate(false, 'Admin')

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Group'
      pageData:
        title:     'Groups'
        home:      'groups'
        object:    'Group'
        objects:   'Groups'
        navupdate: '#groups'
        notes:     [
          'Groups are ...'
        ]
        buttons: [
          { name: 'New Group', 'data-type': 'new', class: 'btn--success' },
        ]
      container: @el.closest('.content')
    )

App.Config.set( 'Group', { prio: 1500, name: 'Groups', parent: '#manage', target: '#manage/groups', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )