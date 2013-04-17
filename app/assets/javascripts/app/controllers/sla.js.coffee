class Index extends App.ControllerContent
  constructor: ->
    super
    
    # check authentication
    return if !@authenticate()
    
    new App.ControllerGenericIndex(
      el: @el,
      id: @id,
      genericObject: 'Sla',
      pageData: {
        title: 'SLA',
        home: 'slas',
        object: 'SLA',
        objects: 'SLAs',
        navupdate: '#slas',
        notes: [
#          'SLA are ...'
        ],
        buttons: [
          { name: 'New SLA', 'data-type': 'new', class: 'primary' },
        ],
      },
    )

App.Config.set( 'slas', Index, 'Routes' )
App.Config.set( 'Sla', { prio: 2900, parent: '#admin', name: 'SLAs', target: '#slas', role: ['Admin'] }, 'NavBar' )

