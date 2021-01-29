class Organization extends App.ControllerSubContent
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
      defaultSortBy: 'name'
      pageData:
        home: 'organizations'
        object: 'Organization'
        objects: 'Organizations'
        pagerAjax: true
        pagerBaseUrl: '#manage/organizations/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
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

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )


App.Config.set('Organization', { prio: 2000, name: 'Organizations', parent: '#manage', target: '#manage/organizations', controller: Organization, permission: ['admin.organization'] }, 'NavBarAdmin')
