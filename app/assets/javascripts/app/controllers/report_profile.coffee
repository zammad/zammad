class ReportProfile extends App.ControllerSubContent
  requiredPermission: 'admin.report_profile'
  header: __('Report Profile')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'ReportProfile'
      defaultSortBy: 'name'
      pageData:
        home: 'report_profiles'
        object: __('Report Profile')
        objects: __('Report Profiles')
        pagerAjax: true
        pagerBaseUrl: '#manage/report_profiles/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#report_profiles'
        notes: [
#          'Report Profile are ...'
        ]
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

    @genericController.paginate( @page || 1 )

App.Config.set('ReportProfile', { prio: 8000, name: __('Report Profiles'), parent: '#manage', target: '#manage/report_profiles', controller: ReportProfile, permission: ['admin.report_profile'] }, 'NavBarAdmin')
