class App.ContentPermanentWidget extends App.ControllerPermanent
  className: 'container aaa'

  constructor: ->
    super

App.Config.set( 'content_permanent', App.ContentPermanentWidget, 'Widgets' )
