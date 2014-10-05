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
      directValue += 1
    if directValue > 1
      for item in @setting.options['form']
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
      el: @el.find('.form-item'),
      model: { configure_attributes: @configure_attributes, className: '' },
      autofocus: false,
    )

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    directValue = 0
    directData  = undefined
    for item in @setting.options['form']
      directValue += 1
      directData  = params[item.name]

    if directValue > 1
      state = {
        value: params
      }
      #App.Config.set((@setting.name, params)
    else
      state = {
        value: directData
      }
      #App.Config.set(@setting.name, directData)

    @setting['state'] = state
    ui = @
    @setting.save(
      done: =>

        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent('Update successful!')
          timeout: 1500
        }
        ui.render()
        #App.Event.trigger( 'ui:rerender' )
        # login check
        App.Auth.loginCheck()
    )
