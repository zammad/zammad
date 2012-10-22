$ = jQuery.sub()

class Index extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    new App.ControllerGenericIndex(
      el: @el,
      id: @id,
      genericObject: 'User',
      defaultSortBy: 'login',
      ignoreObjectIDs: [1], 
      pageData: {
        title: 'Users',
        home: 'users',
        object: 'User',
        objects: 'Users',
        navupdate: '#users',
        notes: [
          'Users are for any person in the system. Agents (Owners, Resposbiles, ...) and Customers.'
        ],
        buttons: [
#          { name: 'List', 'data-type': '', class: 'active' },
          { name: 'New User', 'data-type': 'new', class: 'primary' },
        ],
      }
    )

Config.Routes['users'] = Index

#class App.Users extends App.Router
#  routes:
#    'users/new':      New
#    'users/:id/edit': Edit
#    'users':          Index
#
#Config.Controller.push App.Users
