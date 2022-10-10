class Template extends App.ControllerSubContent
  requiredPermission: 'admin.template'
  header: __('Templates')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Template'
      defaultSortBy: 'name'
      pageData:
        home: 'templates'
        object: __('Template')
        objects: __('Templates')
        pagerAjax: true
        pagerBaseUrl: '#manage/templates/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#templates'
        notes: [
          __('Text modules are …')
        ]
        buttons: [
          { name: __('New Template'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('Templates', { prio: 2320, name: __('Templates'), parent: '#manage', target: '#manage/templates', controller: Template, permission: ['admin.template'] }, 'NavBarAdmin')
