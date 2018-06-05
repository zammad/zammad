class App.SettingsAreaItem extends App.Controller
  template: 'settings/item'
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>

    # input validation for error handling
    if !@setting.options
      throw "No such options for #{@setting.name}"

    if !@setting.options.form
      throw "No such options.form for #{@setting.name}"

    # defaults
    directValue = 0
    for item in @setting.options['form']
      directValue += 1
    if directValue > 1
      for item in @setting.options['form']
        item['default'] = @setting.state_current.value[item.name]
    else
      item['default'] = @setting.state_current.value

    # form
    @configure_attributes = @setting.options['form']

    for attribute in @configure_attributes
      if attribute.tag is 'boolean'
        attribute.translate = true

    # item
    @html App.view(@template)(
      setting: @setting
    )

    new App.ControllerForm(
      el: @el.find('.form-item')
      model: { configure_attributes: @configure_attributes, className: '' }
      autofocus: false
    )

  update: (e) =>
    e.preventDefault()
    @formDisable(e)
    params = @formParam(e.target)

    directValue = 0
    directData  = undefined
    for item in @setting.options['form']
      directValue += 1
      directData  = params[item.name]
    value = undefined
    if directValue > 1
      value = params
    else
      value = directData
    App.Setting.set(@setting['name'], value, doneLocal: => @formEnable(e))
