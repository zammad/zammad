class App.TicketZoomSetting extends App.Controller
  events:
    'click .js-setting': 'show'

  constructor: ->
    super
    return if !@permissionCheck('admin')
    @render()

  render: ->
    @html(App.view('ticket_zoom/setting')())

  show: ->
    new Modal()

class Modal extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: false
  head: 'Settings'

  constructor: ->
    super

  render: =>
    super

  post: =>
    new App.SettingsArea(
      area: 'UI::TicketZoom'
      el: @el.find('.modal-body')
    )

  content: ->
    App.view('generic/page_loading')()
