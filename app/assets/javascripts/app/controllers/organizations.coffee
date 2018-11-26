class Index extends App.ControllerSubContent
  requiredPermission: 'admin.organization'
  header: 'Organizations'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Organization'
      importCallback: ->
        new App.Import(
          baseUrl: '/api/v1/organizations'
          container: @el.closest('.content')
        )
      pageData:
        home: 'organizations'
        object: 'Organization'
        objects: 'Organizations'
        navupdate: '#organizations'
        notes: [
          'Organizations are for any person in the system. Agents (Owners, Resposbiles, ...) and Customers.'
        ]
        buttons: [
          { name: 'Import', 'data-type': 'import', class: 'btn' }
          { name: 'New Organization', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set('Organization', { prio: 2000, name: 'Organizations', parent: '#manage', target: '#manage/organizations', controller: Index, permission: ['admin.organization'] }, 'NavBarAdmin')
