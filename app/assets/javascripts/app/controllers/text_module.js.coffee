class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    new App.ControllerGenericIndex(
      el: @el,
      id: @id,
      genericObject: 'TextModule',
      pageData: {
        title: 'TextModules',
        home: 'text_modules',
        object: 'TextModule',
        objects: 'TextModules',
        navupdate: '#text_modules',
        notes: [
          'TextModules are ...'
        ],
        buttons: [
          { name: 'New TextModule', 'data-type': 'new', class: 'primary' },
        ],
      },
    )

App.Config.set( 'TextModule', { prio: 2300, name: 'TextModules', parent: '#manage', target: '#manage/text_modules', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )