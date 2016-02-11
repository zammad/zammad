class App.DashboardFirstSteps extends App.Controller
  events:
    'click a': 'scrollIntoView'

  constructor: ->
    super

    @load()

  load: =>

    @ajax(
      id:    'first_steps'
      type:  'GET'
      url:   @apiPath + '/first_steps'
      success: (data) =>
        @render(data)
    )

  render: (data) ->
    @html App.view('dashboard/first_steps')(
      data: data
    )

  scrollIntoView: (e) ->
    href = $(e.currentTarget).attr('href')
    return if !href
    return if href is '#'
    delay = ->
      element = $("[href='#{href}']").get(0)
      return if !element
      element.scrollIntoView()
    @delay(delay, 20)
