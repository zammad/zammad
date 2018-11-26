class Index extends App.ControllerSubContent
  requiredPermission: 'admin.report_profile'
  header: 'Report Profile'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'ReportProfile'
      pageData:
        home: 'report_profiles'
        object: 'Report Profile'
        objects: 'Report Profiles'
        navupdate: '#report_profiles'
        notes: [
#          'Report Profile are ...'
        ]
        buttons: [
          { name: 'New Profile', 'data-type': 'new', class: 'primary' }
        ]
      container: @el.closest('.content')
    )

App.Config.set('ReportProfile', { prio: 8000, name: 'Report Profiles', parent: '#manage', target: '#manage/report_profiles', controller: Index, permission: ['admin.report_profile'] }, 'NavBarAdmin')
