class App.TimeAccountingSettings extends App.Controller
  @include App.TimeAccountingUnitMixin

  events:
    'click .js-timeAccountingSettings':      'saveSettings'
    'click .js-timeAccountingSettingsReset': 'resetSettings'
    'change #timeAccountingUnit':            'changeTimeAccountingUnit'

  elements:
    '#timeAccountingUnit':       'timeAccountingUnit'
    '#timeAccountingCustomUnit': 'timeAccountingCustomUnit'

  constructor: ->
    super

    @render()

  render: =>
    @html App.view('time_accounting/settings')(
      timeAccountingUnit:       App.Setting.get('time_accounting_unit')
      timeAccountingCustomUnit: App.Setting.get('time_accounting_unit_custom')
      timeUnits:                @timeAccountingUnitOptions()
    )

    configure_attributes = [
      { name: 'condition',  display: __('Conditions for affected objects'), tag: 'time_accouting_condition', workflow_object: 'Ticket', disable_operators: ['has changed', 'changed to'], null: false, preview: false },
    ]

    filter_params = App.Setting.get('time_accounting_selector')

    @filter = new App.ControllerForm(
      el: @$('.js-selector')
      model:
        configure_attributes: configure_attributes,
      params: filter_params
      autofocus: true
    )

  changeTimeAccountingUnit: (e) =>
    @$('#timeAccountingCustomUnit').toggle $(e.target).val() is 'custom'
    @$('#timeAccountingCustomUnit').focus() if $(e.target).val() is 'custom'

  saveSettings: (e) =>
    e.preventDefault()

    timeAccountingSelector   = @formParam(@filter.form)
    timeAccountingUnit       = @timeAccountingUnit.val()
    timeAccountingCustomUnit = @timeAccountingCustomUnit.val()

    if timeAccountingUnit is 'custom' and _.isEmpty(timeAccountingCustomUnit)
      timeAccountingUnit = ''
    else if timeAccountingUnit isnt 'custom' and not _.isEmpty(timeAccountingCustomUnit)
      timeAccountingCustomUnit = ''

    # save time accounting settings
    App.Setting.set('time_accounting_selector', timeAccountingSelector)
    App.Setting.set('time_accounting_unit', timeAccountingUnit)
    App.Setting.set('time_accounting_unit_custom', timeAccountingCustomUnit, notify: true)

  resetSettings: (e) ->
    e.preventDefault()

    # reset time accounting settings
    App.Setting.set('time_accounting_selector', {})
    App.Setting.set('time_accounting_unit', '')
    App.Setting.set('time_accounting_unit_custom', '', notify: true)

