$ = jQuery.sub()

class Index extends App.Controller
  constructor: ->
    super
    
    # check authentication
    return if !@authenticate()
    
    new App.ControllerGenericIndex(
      el: @el,
      id: @id,
      genericObject: 'Overview',
      pageData: {
        title: 'Overviews',
        home: 'overviews',
        object: 'Overview',
        objects: 'Overviews',
        navupdate: '#overviews',
        notes: [
          'Overview are ...'
        ],
        buttons: [
          { name: 'New Overview', 'data-type': 'new', class: 'primary' },
        ],
      },
    )

App.Config.set( 'overviews', Index, 'Routes' )
App.Config.set( 'Overview', { prio: 2300, parent: '#admin', name: 'Overviews', target: '#overviews', role: ['Admin'] }, 'NavBar' )

