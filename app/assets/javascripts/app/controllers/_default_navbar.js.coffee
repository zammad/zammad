App.Config.set( 'User', {
  prio:   10000,
  parent: '',
  callback: ->
    item = {}
    item['name'] = App.Session.get( 'login' )
    return item
  target: '#current_user',
  role:   [ 'Agent', 'Customer' ]
}, 'NavBarRight' )

App.Config.set( 'Admin', { prio: 10000, parent: '', name: 'Admin', target: '#manage', role: ['Admin'] }, 'NavBar' )
App.Config.set( 'Misc', { prio: 90000, parent: '', name: 'Tools', target: '#tools', child: true }, 'NavBar' )
