class Organization extends App.ControllerSubContent
  @requiredPermission: 'admin.organization'
  header: __('Organizations')
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
      searchBar: true
      searchQuery: @search_query
      searchShortcuts: [
        { query: 'active:false', label: __('Inactive only') }
        { query: 'shared:true', label: __('Shared organizations') }
        { query: 'created_at:>now-1M', label: __('Created within last month') }
      ]
      pageData:
        home: 'organizations'
        object: __('Organization')
        objects: __('Organizations')
        searchPlaceholder: __('Search for organizations')
        pagerAjax: true
        pagerBaseUrl: '#manage/organizations/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#organizations'
        buttons: [
          { name: __('Import'), 'data-type': 'import', class: 'btn' }
          { name: __('New Organization'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)


App.Config.set('Organization', { prio: 2000, name: __('Organizations'), parent: '#manage', target: '#manage/organizations', controller: Organization, permission: ['admin.organization'] }, 'NavBarAdmin')
