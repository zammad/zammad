class Index extends App.ControllerContent
  requiredPermission: 'admin.macro'
  constructor: ->
    super

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Macro'
      pageData:
        title: 'Macros'
        home: 'macros'
        object: 'Macro'
        objects: 'Macros'
        navupdate: '#macros'
        notes: [
          'TextModules are ...'
        ]
        buttons: [
          { name: 'New Macro', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set('Macros', { prio: 2310, name: 'Macros', parent: '#manage', target: '#manage/macros', controller: Index, permission: ['admin.macro'] }, 'NavBarAdmin')
