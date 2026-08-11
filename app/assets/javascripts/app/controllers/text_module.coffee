class TextModule extends App.ControllerSubContent
  @requiredPermission: 'admin.text_module'
  header: __('Text Modules')
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
      searchBar: true
      searchQuery: @search_query
      searchShortcuts: [
        { query: 'active:true', label: __('Active only') }
        { query: 'created_at:>now-1M', label: __('Created within last month') }
        { query: 'updated_at:>now-7d', label: __('Updated within last 7 days') }
      ]
      pageData:
        home:      'text_modules'
        object:    __('Text module')
        objects:   __('Text Modules')
        searchPlaceholder: __('Search for text modules')
        pagerAjax: true
        pagerBaseUrl: '#manage/text_modules/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#text_modules'
        notes:     [
          __('Text modules are …')
        ]
        buttons: [
          { name: __('Import'),          'data-type': 'import', class: 'btn' }
          { name: __('New text module'), 'data-type': 'new',    class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('TextModule', { prio: 2300, name: __('Text Modules'), parent: '#manage', target: '#manage/text_modules', controller: TextModule, permission: ['admin.text_module'] }, 'NavBarAdmin')
