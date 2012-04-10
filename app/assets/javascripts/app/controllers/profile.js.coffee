$ = jQuery.sub()
Note = App.Note

$.fn.item = ->
  elementID   = $(@).data('id')
  elementID or= $(@).parents('[data-id]').data('id')
  Note.find(elementID)

class Index extends App.Controller
  events:
    'focusin [data-type=edit]':     'edit_in'

  constructor: ->
    super
    
    # set title
    @title 'Profile'

    @render()
    
    @navupdate '#profile'

    
  render: ->
    @html App.view('profile')()

Config.Routes['profile'] = Index

#class App.Profile extends App.Router
#  routes:
#    'profile': Index
#Config.Controller.push App.Profile