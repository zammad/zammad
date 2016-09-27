class Index extends App.ControllerSubContent
  requiredPermission: 'admin.organization'
  header: 'Organizations'
  constructor: ->
    super

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Organization'
      pageData:
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

App.Config.set('Organization', { prio: 2000, name: 'Organizations', parent: '#manage', target: '#manage/organizations', controller: Index, permission: ['admin.organization'] }, 'NavBarAdmin')
