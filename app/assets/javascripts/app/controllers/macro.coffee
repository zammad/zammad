class Index extends App.ControllerSubContent
  requiredPermission: 'admin.macro'
  header: 'Macros'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Macro'
      pageData:
        home: 'macros'
        object: 'Macro'
        objects: 'Macros'
        navupdate: '#macros'
        notes: [
          'Text modules are ...'
        ]
        buttons: [
          { name: 'New Macro', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set('Macros', { prio: 2310, name: 'Macros', parent: '#manage', target: '#manage/macros', controller: Index, permission: ['admin.macro'] }, 'NavBarAdmin')
