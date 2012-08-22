$ = jQuery.sub()

class Index extends App.Controller
  constructor: ->
    super
    
    # check authentication
    return if !@authenticate()
    
    new App.ControllerGenericIndex(
      el: @el,
      id: @id,
      genericObject: App.Organization,
      pageData: {
        title: 'Organizations',
        home: 'organizations',
        object: 'Organization',
        objects: 'Organizations',
        navupdate: '#organizations',
        notes: [
          'Organizations are for any person in the system. Agents (Owners, Resposbiles, ...) and Customers.'
        ],
        buttons: [
          { name: 'New Organization', 'data-type': 'new', class: 'primary' },
        ],
      },
    )

#Config.Routes['organizations/new'] = New
#Config.Routes['organizations/:id/edit'] = Edit
Config.Routes['organizations'] = Index


Config.NavBar['Admin'] = { prio: 10000, parent: '', name: 'Manage', target: '#admin', role: ['Admin'] }
Config.NavBar['AdminUser'] = { prio: 1000, parent: '#admin', name: 'Users', target: '#users', role: ['Admin'] }
Config.NavBar['AdminGroup'] = { prio: 1500, parent: '#admin', name: 'Groups', target: '#groups', role: ['Admin'] }
Config.NavBar['AdminOrganization'] = { prio: 2000, parent: '#admin', name: 'Organizations', target: '#organizations', role: ['Admin'] }
Config.NavBar['AdminChannels'] = { prio: 2500, parent: '#admin', name: 'Channels', target: '#channels', role: ['Admin'] }
Config.NavBar['AdminTrigger'] = { prio: 3000, parent: '#admin', name: 'Trigger', target: '#trigger', role: ['Admin'] }
Config.NavBar['AdminScheduler'] = { prio: 3500, parent: '#admin', name: 'Scheduler', target: '#scheduler', role: ['Admin'] }


Config.NavBar['Setting']         = { prio: 20000, parent: '', name: 'Settings', target: '#settings', role: ['Admin'] }
Config.NavBar['SettingSystem']   = { prio: 1400, parent: '#settings', name: 'System', target: '#settings/system', role: ['Admin'] }
Config.NavBar['SettingSecurity'] = { prio: 1500, parent: '#settings', name: 'Security', target: '#settings/security', role: ['Admin'] }
Config.NavBar['SettingTicket']   = { prio: 1600, parent: '#settings', name: 'Ticket', target: '#settings/ticket', role: ['Admin'] }
Config.NavBar['SettingObject']   = { prio: 1700, parent: '#settings', name: 'Objects', target: '#settings/objects', role: ['Admin'] }

Config.NavBar['Packages']   = { prio: 1800, parent: '#settings', name: 'Packages', target: '#packages', role: ['Admin'] }


Config.NavBar['TicketOverview'] = { prio: 1000, parent: '', name: 'Overviews', target: '#ticket_view', role: ['Agent'] }
#Config.NavBar[''] = { prio: 1000, parent: '#ticket_view', name: 'My assigned Tickets (51)', target: '#ticket_view/my_assigned', role: ['Agent'] }
#Config.NavBar[''] = { prio: 1000, parent: '#ticket_view', name: 'Unassigned Tickets (133)', target: '#ticket_view/all_unassigned', role: ['Agent'] }


#Config.NavBar['Network'] = { prio: 1500, parent: '', name: 'Networking', target: '#network', role: ['Anybody', 'Customer', 'Agent'] }
#Config.NavBar[''] = { prio: 1600, parent: '', name: 'anybody+agent', target: '#aa', role: ['Anybody', 'Agent'] }
#Config.NavBar[''] = { prio: 1600, parent: '', name: 'Anybody', target: '#anybody', role: ['Anybody'] }
Config.NavBar['CustomerTickets'] = { prio: 1600, parent: '', name: 'Tickets', target: '#customer_tickets', role: ['Customer'] }

Config.NavBarRight['TicketNew'] = { prio: 8000, parent: '', name: 'New', target: '#ticket_create', role: ['Agent'] }
Config.NavBarRight['User'] = {
  prio:   10000,
  parent: '',
  callback: ->
    item = {}
    item['name'] = window.Session['login']
    return item
  target: '#current_user',
  role:   [ 'Agent', 'Customer' ]
}
Config.NavBarRight['UserProfile'] = { prio: 1700, parent: '#current_user', name: 'Profile', target: '#profile', role: [ 'Agent', 'Customer' ] }
Config.NavBarRight['UserLogout']  = { prio: 1800, parent: '#current_user', name: 'Sign out', target: '#logout', divider: true, role: [ 'Agent', 'Customer' ] }

