class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate(false, 'Admin')

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Overview'
      pageData:
        title: 'Overviews'
        home: 'overviews'
        object: 'Overview'
        objects: 'Overviews'
        navupdate: '#overviews'
        notes: [
          'Overview are ...'
        ]
        buttons: [
          { name: 'New Overview', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      large: true,
    )

App.Config.set( 'Overview', { prio: 2300, name: 'Overviews', parent: '#manage', target: '#manage/overviews', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )