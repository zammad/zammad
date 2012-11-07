$ = jQuery.sub()

class Index extends App.Controller
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

App.Config.set( 'overviews', Index, 'Routes' )
App.Config.set( 'Overview', { prio: 2300, parent: '#admin', name: 'Overviews', target: '#overviews', role: ['Admin'] }, 'NavBar' )

