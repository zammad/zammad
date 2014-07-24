App.Config.set( 'User', {
  prio:   1000,
  parent: '',
  callback: ->
    item = {}
    item['name'] = App.Session.get( 'login' )
    item['image'] = App.Session.get( 'image' )
    return item
  target: '#current_user',
  class:  'user'
  role:   [ 'Agent', 'Customer' ]
}, 'NavBarRight' )

App.Config.set( 'Admin', { prio: 9000, parent: '', name: 'Admin', target: '#manage', role: ['Admin'] }, 'NavBarRight' )
App.Config.set( 'New', { prio: 20000, parent: '', name: 'New', target: '#new', class: 'add' }, 'NavBarRight' )

App.Config.set( 'Misc', { prio: 90000, parent: '', name: 'Tools', target: '#tools', child: true }, 'NavBar' )
