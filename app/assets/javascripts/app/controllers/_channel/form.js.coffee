class App.ChannelForm extends App.Controller
  events:
    'change form.js-params': 'updateParams'
    'keyup form.js-params': 'updateParams'

  constructor: ->
    super
    @title 'Form'
    @render()
    @updateParams()
    new App.SettingsArea(
      el:   @el.find('.js-settings')
      area: 'Form::Base'
    )

  render: ->
    @html App.view('channel/form')(
      baseurl: window.location.origin
    )

  updateParams: ->
    quote = (string) ->
      string.replace('\'', '\\\'')
    params = @formParam(@$('.js-params'))
    paramString = ''
    for key, value of params
      if paramString != ''
        paramString += ",\n"
      if value == 'true' || value == 'false'
        paramString += "    #{key}: #{value}"
      else
        paramString += "    #{key}: '#{quote(value)}'"
    @$('.js-modal-params').html(paramString)

App.Config.set( 'Form', { prio: 2000, name: 'Form', parent: '#channels', target: '#channels/form', controller: App.ChannelForm, role: ['Admin'] }, 'NavBarAdmin' )
