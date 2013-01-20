class Index extends App.Controller
#  events:
#    'focusin [data-type=edit]':     'edit_in'

  constructor: ->
    super
    
    # set title
    @title 'Profile'

    @render()
    
    @navupdate '#profile'

    
  render: ->
    @html App.view('profile')()


App.Config.set( 'profile', Index, 'Routes' )
App.Config.set( 'Profile', { prio: 1700, parent: '#current_user', name: 'Profile', target: '#profile', role: [ 'Agent', 'Customer' ] }, 'NavBarRight' )
