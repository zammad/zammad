$ = jQuery.sub()

class Index extends Spine.Controller

  constructor: ->
    super
    @signout()

  signout: ->

    # remove remote session
    App.Auth.logout()

    # remoce local session
    @log 'Session', window.Session
    window.Session = {}
    @log 'Session', window.Session
    App.Event.trigger 'ajax:auth'

    # redirect to login 
    @navigate 'login'

App.Config.set( 'logout', Index, 'Routes' )

App.Config.set( 'Logout', { prio: 1800, parent: '#current_user', name: 'Sign out', target: '#logout', divider: true, role: [ 'Agent', 'Customer' ] }, 'NavBarRight' )
