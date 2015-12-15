# coffeelint: disable=no_unnecessary_double_quotes
class App.ChannelForm extends App.Controller
  events:
    'change form.js-params': 'updateParams'
    'keyup form.js-params': 'updateParams'
    'click .js-formSetting': 'toggleFormSetting'

  elements:
    '.js-paramsBlock': 'paramsBlock'
    '.js-formSetting input': 'formSetting'

  constructor: ->
    super
    @title 'Form'
    @subscribeId = App.Setting.subscribe(@render, initFetch: true)

  render: =>
    App.Setting.unsubscribe(@subscribeId)
    setting = App.Setting.findByAttribute('name', 'form_ticket_create')
    @html App.view('channel/form')(
      baseurl: window.location.origin
      formSetting: setting.state_current.value
    )

    @paramsBlock.each (i, block) ->
      hljs.highlightBlock block

    @updateParams()

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  updateParams: ->
    quote = (string) ->
      string = string.replace('\'', '\\\'')
        .replace(/\</g, '&lt;')
        .replace(/\>/g, '&gt;')
    params = @formParam(@$('.js-params'))
    paramString = ''
    for key, value of params
      if value != ''
        if paramString != ''
          paramString += ",\n"
        if value == 'true' || value == 'false'
          paramString += "    #{key}: #{value}"
        else
          paramString += "    #{key}: '#{quote(value)}'"
    @$('.js-modal-params').html(paramString)

  toggleFormSetting: =>
    value = @formSetting.prop('checked')
    setting = App.Setting.findByAttribute('name', 'form_ticket_create')
    setting.state_current = { value: value }
    setting.save()

App.Config.set( 'Form', { prio: 2000, name: 'Form', parent: '#channels', target: '#channels/form', controller: App.ChannelForm, role: ['Admin'] }, 'NavBarAdmin' )
