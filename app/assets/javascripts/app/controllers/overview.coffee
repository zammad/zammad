class Overview extends App.ControllerSubContent
  requiredPermission: 'admin.overview'
  header: 'Overviews'
  constructor: ->
    super

    # update group by with current attributes
    for attribute in App.Overview.configure_attributes
      if attribute.name is 'group_by'
        attribute.options = App.Overview.groupByAttributes()

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Overview'
      defaultSortBy: 'prio'
      #groupBy: 'role'
      pageData:
        home: 'overviews'
        object: 'Overview'
        objects: 'Overviews'
        navupdate: '#overviews'
        notes: [
          'Overview are ...'
        ]
        buttons: [
          { name: 'New Overview', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      large: true
      dndCallback: (e, item) =>
        items = @el.find('table > tbody > tr')
        prios = []
        prio = 0
        for item in items
          prio += 1
          id = $(item).data('id')
          prios.push [id, prio]

        @ajax(
          id:          'overview_prio'
          type:        'POST'
          url:         "#{@apiPath}/overviews_prio"
          processData: true
          data:        JSON.stringify(prios: prios)
        )
    )

App.Config.set('Overview', { prio: 2300, name: 'Overviews', parent: '#manage', target: '#manage/overviews', controller: Overview, permission: ['admin.overview'] }, 'NavBarAdmin')
