class App.UiElement.timezone extends App.UiElement.ApplicationUiElement
  @render: (attribute) ->

    attribute.options = []
    timezones = App.Config.get('timezones')

    # build list based on config
    for timezone_value, timezone_diff of timezones
      if timezone_diff > 0
        timezone_diff = '+' + timezone_diff
      item =
        name:  "#{timezone_value} (GMT#{timezone_diff})"
        value: timezone_value
      attribute.options.push item

    # add null selection if needed
    @addNullOption( attribute, params )

    # sort attribute.options
    @sortOptions( attribute, params )

    # finde selected/checked item of list
    @selectedOptions( attribute, params )

    $( App.view('generic/select')( attribute: attribute ) )
