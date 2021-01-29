class Role extends App.ControllerSubContent
  requiredPermission: 'admin.role'
  header: 'Roles'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Role'
      defaultSortBy: 'name'
      pageData:
        home:      'roles'
        object:    'Role'
        objects:   'Roles'
        pagerAjax: true
        pagerBaseUrl: '#manage/roles/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#roles'
        notes:     [
          'Roles are ...'
        ]
        buttons: [
          { name: 'New Role', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('Role', { prio: 1600, name: 'Roles', parent: '#manage', target: '#manage/roles', controller: Role, permission: ['admin.role'] }, 'NavBarAdmin')
