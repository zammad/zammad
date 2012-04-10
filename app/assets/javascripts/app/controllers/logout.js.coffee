$ = jQuery.sub()

class Index extends Spine.Controller

  constructor: ->
    super

    @signout()
  
  signout: ->
    
    # remove remote session
    auth = new App.Auth
    auth.logout()

    # remoce local session
    @log 'Session', window.Session
    window.Session = {}
    @log 'Session', window.Session
    Spine.trigger 'navrebuild'
    
    # redirect to login 
    @navigate 'login'

Config.Routes['logout'] = Index

#class App.Logout extends App.Router
#  routes:
#    'logout': Index
#Config.Controller.push App.Logout