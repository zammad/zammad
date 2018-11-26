class Index extends App.ControllerSubContent
  requiredPermission: 'admin.role'
  header: 'Roles'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Role'
      pageData:
        home:      'roles'
        object:    'Role'
        objects:   'Roles'
        navupdate: '#roles'
        notes:     [
          'Roles are ...'
        ]
        buttons: [
          { name: 'New Role', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set('Role', { prio: 1600, name: 'Roles', parent: '#manage', target: '#manage/roles', controller: Index, permission: ['admin.role'] }, 'NavBarAdmin')
