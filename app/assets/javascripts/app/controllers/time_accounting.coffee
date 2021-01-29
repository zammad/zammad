class TimeAccounting extends App.ControllerSubContent
  requiredPermission: 'admin.time_accounting'
  header: 'Time Accounting'
  events:
    'change .js-timeAccountingSetting input': 'setTimeAccounting'
    'click .js-timePickerYear': 'setYear'
    'click .js-timePickerMonth': 'setMonth'
    'click .js-timeAccountingFilter': 'setFilter'
    'click .js-timeAccountingFilterReset': 'resetFilter'

  elements:
    '.js-timeAccountingSetting input': 'timeAccountingSetting'

  constructor: ->
    super

    current      = new Date()
    currentDay   = current.getDate()
    currentMonth = current.getMonth() + 1
    currentYear  = current.getFullYear()
    currentWeek  = current.getWeek()
    if !@month
      @month = currentMonth
    if !@year
      @year = currentYear

    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    currentNewTagSetting = @Config.get('time_accounting') || false
    #return if currentNewTagSetting is @lastNewTagSetting
    @lastNewTagSetting = currentNewTagSetting

    timeRangeYear = []
    year = new Date().getFullYear()
    for item in [year-2..year]
      record = {
        display: item
        value: item
      }
      timeRangeYear.push record

    timeRangeMonth = [
      {
        display: 'Jan'
        value: 1
      },
      {
        display: 'Feb'
        value: 2
      },
      {
        display: 'Mar'
        value: 3
      },
      {
        display: 'Apr'
        value: 4,
      },
      {
        display: 'May'
        value: 5,
      },
      {
        display: 'Jun'
        value: 6,
      },
      {
        display: 'Jul'
        value: 7,
      },
      {
        display: 'Aug'
        value: 8,
      },
      {
        display: 'Sep'
        value: 9,
      },
      {
        display: 'Oct'
        value: 10,
      },
      {
        display: 'Nov'
        value: 11,
      },
      {
        display: 'Dec'
        value: 12,
      },
    ]

    @html App.view('time_accounting/index')(
      timeRangeYear: timeRangeYear
      timeRangeMonth: timeRangeMonth
      year: @year
      month: @month
      apiPath: @apiPath
    )

    configure_attributes = [
      { name: 'condition',  display: 'Conditions for effected objects', tag: 'ticket_selector', null: false, preview: false, action: false, hasChanged: false },
    ]

    filter_params = App.Setting.get('time_accounting_selector')
    @filter = new App.ControllerForm(
      el: @$('.js-selector')
      model:
        configure_attributes: configure_attributes,
      params: filter_params
      autofocus: true
    )

    new ByTicket(
      el: @$('.js-tableTicket')
      year: @year
      month: @month
    )

    new ByCustomer(
      el: @$('.js-tableCustomer')
      year: @year
      month: @month
    )

    new ByOrganization(
      el: @$('.js-tableOrganization')
      year: @year
      month: @month
    )

  setFilter: (e) =>
    e.preventDefault()

    # get form data
    params = @formParam(@filter.form)

    # save filter settings
    App.Setting.set('time_accounting_selector', params, notify: true)

  resetFilter: (e) ->
    e.preventDefault()

    # save filter settings
    App.Setting.set('time_accounting_selector', {}, notify: true)

  setTimeAccounting: (e) =>
    value = @timeAccountingSetting.prop('checked')
    App.Setting.set('time_accounting', value)

  setYear: (e) =>
    e.preventDefault()
    @year = $(e.target).data('type')
    @render()

  setMonth: (e) =>
    e.preventDefault()
    @month = $(e.target).data('type')
    @render()

class ByTicket extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      id:    'by_ticket'
      type:  'GET'
      url:   "#{@apiPath}/time_accounting/log/by_ticket/#{@year}/#{@month}"
      processData: true
      success: (data, status, xhr) =>
        @render(data)
    )

  render: (rows) =>
    @html App.view('time_accounting/by_ticket')(
      rows: rows
    )

class ByCustomer extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      id:    'by_customer'
      type:  'GET'
      url:   "#{@apiPath}/time_accounting/log/by_customer/#{@year}/#{@month}"
      processData: true
      success: (data, status, xhr) =>
        @render(data)
    )

  render: (rows) =>
    @html App.view('time_accounting/by_customer')(
      rows: rows
    )

class ByOrganization extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      id:    'by_organization'
      type:  'GET'
      url:   "#{@apiPath}/time_accounting/log/by_organization/#{@year}/#{@month}"
      processData: true
      success: (data, status, xhr) =>
        @render(data)
    )

  render: (rows) =>
    @html App.view('time_accounting/by_organization')(
      rows: rows
    )

App.Config.set('TimeAccounting', { prio: 8500, name: 'Time Accounting', parent: '#manage', target: '#manage/time_accounting', controller: TimeAccounting, permission: ['admin.time_accounting'] }, 'NavBarAdmin')
