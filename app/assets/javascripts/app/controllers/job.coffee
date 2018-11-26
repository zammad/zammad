class Index extends App.ControllerSubContent
  requiredPermission: 'admin.scheduler'
  header: 'Scheduler'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Job'
      defaultSortBy: 'name'
      pageData:
        home: 'Jobs'
        object: 'Scheduler'
        objects: 'Schedulers'
        navupdate: '#Jobs'
        notes: [
          'Scheduler are ...'
        ]
        buttons: [
          { name: 'New Scheduler', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      large: true
    )

App.Config.set('Job', { prio: 3400, name: 'Scheduler', parent: '#manage', target: '#manage/job', controller: Index, permission: ['admin.scheduler'] }, 'NavBarAdmin')
