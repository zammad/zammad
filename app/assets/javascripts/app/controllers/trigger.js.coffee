$ = jQuery.sub()

class Index extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @title 'Triggers'
    @navupdate '#trigger'

    # render page
    @render()

  render: ->
    
    @html App.view('trigger')(
      head: 'some header'
    )
Config.Routes['trigger'] = Index

#class App.Triggers extends App.Router
#  routes:
#    'triggers/web':      New
#    'triggers/email':    New
#    'triggers/twitter':  New
#    'triggers/facebook': New
#    'triggers/new':      New
#    'triggers/:id/edit': Edit
#    'triggers':          Index
#
#Config.Controller.push App.Triggers