class Index extends App.ControllerSubContent
  requiredPermission: 'admin.group'
  header: 'Groups'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Group'
      pageData:
        home:      'groups'
        object:    'Group'
        objects:   'Groups'
        navupdate: '#groups'
        notes:     [
          'Groups are ...'
        ]
        buttons: [
          { name: 'New Group', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set('Group', { prio: 1500, name: 'Groups', parent: '#manage', target: '#manage/groups', controller: Index, permission: ['admin.group'] }, 'NavBarAdmin')
