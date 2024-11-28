class Role extends App.ControllerSubContent
  @requiredPermission: 'admin.role'
  header: __('Roles')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      veryLarge: true
      genericObject: 'Role'
      defaultSortBy: 'name'
      createScreen: 'create'
      editScreen: 'edit'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home:      'roles'
        object:    __('Role')
        objects:   __('Roles')
        pagerAjax: true
        pagerBaseUrl: '#manage/roles/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#roles'
        notes:     [
          __('Roles are …')
        ]
        buttons: [
          { name: __('New Role'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('Role', { prio: 1600, name: __('Roles'), parent: '#manage', target: '#manage/roles', controller: Role, permission: ['admin.role'] }, 'NavBarAdmin')
