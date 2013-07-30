#App.Config.set( 'channels/:target', Index, 'Routes' )
#App.Config.set( 'channels', Index, 'Routes' )

#App.Config.set( 'Channels', { prio: 2500, name: 'Channels', target: '#channels', role: ['Admin'] }, 'NavBarLevel4' )

#App.Config.set( 'Channels', { prio: 2500, parent: '#admin', name: 'Channels', target: '#channels', role: ['Admin'] }, 'NavBar' )

App.Config.set( 'Web', { prio: 1000, name: 'Web', parent: '#channels', target: '#channels/web', controller: App.ChannelWeb, role: ['Admin'] }, 'NavBarLevel44' )
App.Config.set( 'Email', { prio: 2000, name: 'Email', parent: '#channels', target: '#channels/email', controller: App.ChannelEmail, role: ['Admin'] }, 'NavBarLevel44' )
App.Config.set( 'Chat', { prio: 3000, name: 'Chat', parent: '#channels', target: '#channels/chat', controller: App.ChannelChat, role: ['Admin'] }, 'NavBarLevel44' )
App.Config.set( 'Twitter', { prio: 4000, name: 'Twitter', parent: '#channels', target: '#channels/twitter', controller: App.ChannelTwitter, role: ['Admin'] }, 'NavBarLevel44' )
App.Config.set( 'Facebook', { prio: 5000, name: 'Facebook', parent: '#channels', target: '#channels/facebook', controller: App.ChannelFacebook, role: ['Admin'] }, 'NavBarLevel44' )

