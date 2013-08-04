class IndexRouter extends App.ControllerNavSidbar
  configKey: 'NavBarLevel44'

App.Config.set( 'manage', IndexRouter, 'Routes' )
App.Config.set( 'manage/:target', IndexRouter, 'Routes' )
App.Config.set( 'settings/:target', IndexRouter, 'Routes' )
App.Config.set( 'channels/:target', IndexRouter, 'Routes' )
App.Config.set( 'system/:target', IndexRouter, 'Routes' )

App.Config.set( 'Manage', { prio: 1000, name: 'Manage', target: '#manage', role: ['Admin'] }, 'NavBarLevel44' )
App.Config.set( 'Channels', { prio: 2500, name: 'Channels', target: '#channels', role: ['Admin'] }, 'NavBarLevel44' )
App.Config.set( 'Settings', { prio: 7000, name: 'Settings', target: '#settings', role: ['Admin'] }, 'NavBarLevel44' )
App.Config.set( 'System', { prio: 8000, name: 'System', target: '#system', role: ['Admin'] }, 'NavBarLevel44' )

App.Config.set( 'SystemObject', { prio: 1700, parent: '#system', name: 'Objects', target: '#system/objects', controller: true, role: ['Admin'] }, 'NavBarLevel44' )

