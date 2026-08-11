class ReportProfile extends App.ControllerSubContent
  @requiredPermission: 'admin.report_profile'
  header: __('Report Profile')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'ReportProfile'
      defaultSortBy: 'name'
      searchBar: true
      searchQuery: @search_query
      searchShortcuts: [
        { query: 'active:true', label: __('Active only') }
        { query: 'created_at:>now-1M', label: __('Created within last month') }
        { query: 'updated_at:>now-7d', label: __('Updated within last 7 days') }
      ]
      pageData:
        home: 'report_profiles'
        object: __('Report Profile')
        objects: __('Report Profiles')
        searchPlaceholder: __('Search for report profiles')
        pagerAjax: true
        pagerBaseUrl: '#manage/report_profiles/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#report_profiles'
        buttons: [
          { name: __('New Profile'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('ReportProfile', { prio: 8000, name: __('Report Profiles'), parent: '#manage', target: '#manage/report_profiles', controller: ReportProfile, permission: ['admin.report_profile'] }, 'NavBarAdmin')
