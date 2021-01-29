class Group extends App.ControllerSubContent
  requiredPermission: 'admin.group'
  header: 'Groups'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Group'
      defaultSortBy: 'name'
      pageData:
        home:      'groups'
        object:    'Group'
        objects:   'Groups'
        pagerAjax: true
        pagerBaseUrl: '#manage/groups/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#groups'
        notes:     [
          'Groups are ...'
        ]
        buttons: [
          { name: 'New Group', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('Group', { prio: 1500, name: 'Groups', parent: '#manage', target: '#manage/groups', controller: Group, permission: ['admin.group'] }, 'NavBarAdmin')
