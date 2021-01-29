class Macro extends App.ControllerSubContent
  requiredPermission: 'admin.macro'
  header: 'Macros'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Macro'
      defaultSortBy: 'name'
      pageData:
        home: 'macros'
        object: 'Macro'
        objects: 'Macros'
        pagerAjax: true
        pagerBaseUrl: '#manage/macros/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#macros'
        notes: [
          'Text modules are ...'
        ]
        buttons: [
          { name: 'New Macro', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('Macros', { prio: 2310, name: 'Macros', parent: '#manage', target: '#manage/macros', controller: Macro, permission: ['admin.macro'] }, 'NavBarAdmin')
