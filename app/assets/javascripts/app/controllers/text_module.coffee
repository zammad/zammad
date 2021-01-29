class TextModule extends App.ControllerSubContent
  requiredPermission: 'admin.text_module'
  header: 'Text modules'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'TextModule'
      defaultSortBy: 'name'
      importCallback: ->
        new App.Import(
          baseUrl: '/api/v1/text_modules'
          container: @el.closest('.content')
          deleteOption: true
        )
      pageData:
        home:      'text_modules'
        object:    'TextModule'
        objects:   'Text modules'
        pagerAjax: true
        pagerBaseUrl: '#manage/text_modules/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#text_modules'
        notes:     [
          'Text modules are ...'
        ]
        buttons: [
          { name: 'Import',          'data-type': 'import', class: 'btn' }
          { name: 'New text module', 'data-type': 'new',    class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('TextModule', { prio: 2300, name: 'Text modules', parent: '#manage', target: '#manage/text_modules', controller: TextModule, permission: ['admin.text_module'] }, 'NavBarAdmin')
