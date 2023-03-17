class Trigger extends App.ControllerSubContent
  requiredPermission: 'admin.trigger'
  header: __('Triggers')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Trigger'
      defaultSortBy: 'name'
      pageData:
        home: 'triggers'
        object: __('Trigger')
        objects: __('Triggers')
        pagerAjax: true
        pagerBaseUrl: '#manage/trigger/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#triggers'
        notes: [
          __('Triggers are …')
        ]
        buttons: [
          { name: __('New Trigger'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('Trigger', { prio: 3300, name: __('Trigger'), parent: '#manage', target: '#manage/trigger', controller: Trigger, permission: ['admin.trigger'] }, 'NavBarAdmin')
