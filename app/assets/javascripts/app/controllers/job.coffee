class Job extends App.ControllerSubContent
  requiredPermission: 'admin.scheduler'
  header: __('Scheduler')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Job'
      defaultSortBy: 'name'
      pageData:
        home: 'Jobs'
        object: __('Scheduler')
        objects: __('Schedulers')
        pagerAjax: true
        pagerBaseUrl: '#manage/job/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#Jobs'
        notes: [
          __('Schedulers are …')
        ]
        buttons: [
          { name: __('New Scheduler'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('Job', { prio: 3400, name: __('Scheduler'), parent: '#manage', target: '#manage/job', controller: Job, permission: ['admin.scheduler'] }, 'NavBarAdmin')
