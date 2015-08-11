class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Job'
      pageData:
        title: 'Schedulers'
        home: 'schedulers'
        object: 'Scheduler'
        objects: 'Schedulers'
        navupdate: '#schedulers'
        notes: [
          'Scheduler are ...'
        ]
        buttons: [
          { name: 'New Scheduler', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set( 'Scheduler', { prio: 3000, name: 'Schedulers', parent: '#manage', target: '#manage/schedulers', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )