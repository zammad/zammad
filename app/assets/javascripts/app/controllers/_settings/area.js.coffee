class App.SettingsArea extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    App.Setting.bind 'refresh change', @render
    App.Setting.fetch()

  render: =>
    settings = App.Setting.all()
    
    html = $('<div></div>')
    for setting in settings
      if setting.area is @area
        item = new App.SettingsAreaItem( setting: setting ) 
        html.append( item.el )

    @html html

class App.SettingsAreaItem extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>
    # defaults
    directValue = 0
    for item in @setting.options['form']
      directValue = +1

    if directValue > 1
      item['default'] = @setting.state.value[item.name]
    else
      item['default'] = @setting.state.value

    # form
    @configure_attributes = @setting.options['form']

    # item
    @html App.view('settings/item')(
      setting: @setting,
    )

    new App.ControllerForm(
      el: @el.find('#form-item'),
      model: { configure_attributes: @configure_attributes, className: '' },
      autofocus: false,
    )

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    @log 'submit', @setting, params, e.target, typeof @setting.state.value
    directValue = 0
    for item in @setting.options['form']
      directValue = +1

    if directValue > 1
      state = {
        value: params
      }
    else
      state = {
        value: params[@setting.name]
      }

    @setting['state'] = state
    @setting.save(
      success: =>

        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent('Update successful!')
          timeout: 1500
        }

        # login check
        App.Auth.loginCheck()
    )
