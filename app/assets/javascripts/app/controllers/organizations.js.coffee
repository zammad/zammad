class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Organization'
      pageData:
        title: 'Organizations'
        home: 'organizations'
        object: 'Organization'
        objects: 'Organizations'
        navupdate: '#organizations'
        notes: [
          'Organizations are for any person in the system. Agents (Owners, Resposbiles, ...) and Customers.'
        ]
        buttons: [
          { name: 'New Organization', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set( 'Organization', { prio: 2000, name: 'Organizations', parent: '#manage', target: '#manage/organizations', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )