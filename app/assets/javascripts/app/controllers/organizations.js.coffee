class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    new App.ControllerGenericIndex(
      el: @el,
      id: @id,
      genericObject: 'Organization',
      pageData: {
        title: 'Organizations',
        home: 'organizations',
        object: 'Organization',
        objects: 'Organizations',
        navupdate: '#organizations',
        notes: [
          'Organizations are for any person in the system. Agents (Owners, Resposbiles, ...) and Customers.'
        ],
        buttons: [
          { name: 'New Organization', 'data-type': 'new', class: 'primary' },
        ],
      },
    )

#App.Config.set( 'organizations', Index, 'Routes' )
#App.Config.set( 'Organization', { prio: 2000, parent: '#admin', name: 'Organizations', target: '#organizations', role: ['Admin'] }, 'NavBar' )

App.Config.set( 'Organization', { prio: 2000, name: 'Organizations', parent: '#manage', target: '#manage/organizations', controller: Index, role: ['Admin'] }, 'NavBarLevel44' )

