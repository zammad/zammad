class App.ChannelForm extends App.Controller
  constructor: ->
    super
    @title 'Form'
    @render()

    new App.SettingsArea(
      el:   @el.find('.js-settings')
      area: 'Form::Base'
    )

  render: ->
    @html App.view('channel/form')(
      baseurl: window.location.origin
    )
