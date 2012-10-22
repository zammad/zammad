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

Config.Routes['text_modules'] = Index
Config.NavBar['AdminTextModule'] = { prio: 2300, parent: '#admin', name: 'Text Modules', target: '#text_modules', role: ['Admin'] }

