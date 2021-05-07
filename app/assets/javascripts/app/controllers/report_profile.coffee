class ReportProfile extends App.ControllerSubContent
  requiredPermission: 'admin.report_profile'
  header: 'Report Profile'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'ReportProfile'
      defaultSortBy: 'name'
      pageData:
        home: 'report_profiles'
        object: 'Report Profile'
        objects: 'Report Profiles'
        pagerAjax: true
        pagerBaseUrl: '#manage/report_profiles/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#report_profiles'
        notes: [
#          'Report Profile are ...'
        ]
        buttons: [
          { name: 'New Profile', 'data-type': 'new', class: 'primary' }
        ]
      container: @el.closest('.content')
      veryLarge: true
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('ReportProfile', { prio: 8000, name: 'Report Profiles', parent: '#manage', target: '#manage/report_profiles', controller: ReportProfile, permission: ['admin.report_profile'] }, 'NavBarAdmin')
