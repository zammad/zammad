class App.TimeAccountingTypes extends App.Controller
  events:
    'click .js-timeAccountingTypes':      'saveTypes'
    'click .js-timeAccountingTypesReset': 'resetTypes'
    'show.bs.tab':                        'willShow'
  elements:
    '#timeAccountingTypes': 'timeAccountingTypes'

  constructor: ->
    super

    @render()

  render: =>
    content = $(App.view('time_accounting/types')())

    selection = App.UiElement.select.render(
      id: 'timeAccountingTypes'
      multiple: false
      null: false
      options:
        true: __('yes')
        false: __('no')
      value: @Config.get('time_accounting_types') or false
      translate: true
    )

    content.find('.js-types').replaceWith(selection)

    @html content

  saveTypes: (e) =>
    e.preventDefault()

    timeAccountingTypes = @timeAccountingTypes.val() is 'true'

    App.Setting.set('time_accounting_types', timeAccountingTypes, notify: true)

  resetTypes: (e) ->
    e.preventDefault()

    App.Setting.set('time_accounting_types', false, notify: true)

  willShow: (e) =>
    @genericController = new App.ControllerGenericIndex(
      genericObject: 'TicketTimeAccountingType'
      container: @el.closest('.content')
      pageData:
        home:      'time_accounting_types'
        object:    __('Activity Type')
        objects:   __('Activity Types')
        navupdate: '#time_accounting_types'
        buttons: [
          { name: __('New Activity Type'), 'data-type': 'new', class: 'btn--success' }
        ]
    )

    @$('.js-table-container').html @genericController.el
