class App.TimeAccountingAccountedTime extends App.Controller
  @include App.TimeAccountingUnitMixin

  events:
    'click .js-timePickerYear':  'setYear'
    'click .js-timePickerMonth': 'setMonth'
    'show.bs.tab':               'willShow'

  tables:
    'by_activity': '.js-tableActivity',
    'by_ticket': '.js-tableTicket',
    'by_customer': '.js-tableCustomer',
    'by_organization': '.js-tableOrganization',

  constructor: ->
    super

    current = new Date()

    @month ||= current.getMonth() + 1
    @year  ||= current.getFullYear()

  render: =>
    year           = new Date().getFullYear()
    timeRangeYear  = [year-2..year]
    timeRangeMonth = [ __('Jan'), __('Feb'), __('Mar'), __('Apr'), __('May'),  __('Jun'),  __('Jul'),  __('Aug'),  __('Sep'),  __('Oct'),  __('Nov'),  __('Dec'),      ]

    @html App.view('time_accounting/accounted_time')(
      month:                    @month
      year:                     @year
      timeRangeYear:            timeRangeYear
      timeRangeMonth:           timeRangeMonth
      timeAccountingUnit:       App.Setting.get('time_accounting_unit')
      timeAccountingCustomUnit: App.Setting.get('time_accounting_unit_custom')
    )

    for identifier, elem of @tables
      new TableByIdentifier(
        identifier: identifier
        el: @$(elem)
        year: @year
        month: @month
      )

  willShow: (e) =>
    @render()

  setYear: (e) =>
    e.preventDefault()
    @year = $(e.target).data('type')
    @render()

  setMonth: (e) =>
    e.preventDefault()
    @month = $(e.target).data('type')
    @render()

class TableByIdentifier extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      id:    @identifier
      type:  'GET'
      url:   "#{@apiPath}/time_accounting/log/#{@identifier}/#{@year}/#{@month}?limit=21"
      processData: true
      success: (data, status, xhr) =>
        @render(data)
    )

  render: (rows) =>
    @html App.view("time_accounting/#{@identifier}")(
      rows: rows
    )

