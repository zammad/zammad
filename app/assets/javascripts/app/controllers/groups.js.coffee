$ = jQuery.sub()

class Index extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    new App.ControllerGenericIndex(
      el: @el,
      id: @id,
      genericObject: 'Group',
      pageData: {
        title: 'Groups',
        home: 'groups',
        object: 'Group',
        objects: 'Groups',
        navupdate: '#groups',
        notes: [
          'Groups are ...'
        ],
        buttons: [
          { name: 'New Group', 'data-type': 'new', class: 'primary' },
        ],
      },
    )


Config.Routes['groups'] = Index

#class App.Groups extends App.Router
#  routes:
#    'groups/new':      New
#    'groups/:id/edit': Edit
#    'groups':          Index
#Config.Controller.push App.Groups