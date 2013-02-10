class Index extends App.ControllerLevel2
  toggleable: false
#  toggleable: true

  constructor: ->
    super

    return if !@authenticate()

    @menu = [
      { name: 'Password',       'target': 'password', controller: App.ProfilePassword, params: {} },
      { name: 'Language',       'target': 'language', controller: App.ProfileLinkedAccounts, params: { area: 'Ticket::Number' } },
      { name: 'Link Accounts',  'target': 'accounts', controller: App.ProfileLinkedAccounts, params: { area: 'Ticket::Number' } },
#      { name: 'Notifications',  'target': 'notify',   controller: App.SettingsArea, params: { area: 'Ticket::Number' } },
    ] 
    @page = {
      title:     'Profile',
      head:      'Profile',
      sub_title: 'Settings'
      nav:       '#profile',
    }

    # render page
    @render()

#  render: ->
#    @html App.view('profile')()


App.Config.set( 'profile/:target', Index, 'Routes' )
App.Config.set( 'profile', Index, 'Routes' )
App.Config.set( 'Profile', { prio: 1700, parent: '#current_user', name: 'Profile', target: '#profile', role: [ 'Agent', 'Customer' ] }, 'NavBarRight' )
