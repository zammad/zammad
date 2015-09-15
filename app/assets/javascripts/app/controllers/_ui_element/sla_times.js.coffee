class App.UiElement.sla_times
  @render: (attribute, params = {}) ->

    item = $( App.view('generic/sla_times')(
      attribute: attribute
      first_response_time: params.first_response_time
      update_time: params.update_time
      close_time: params.close_time
      first_response_time_in_text: @toText(params.first_response_time)
      update_time_in_text: @toText(params.update_time)
      close_time_in_text: @toText(params.close_time)
    ) )

    item.find('.js-timeConvertFrom').bind('keyup', (e) =>
      inText = $(e.target).val()
      inMinutes = @toMinutes(inText)
      if !inMinutes
        $(e.target).addClass('has-error')
      else
        $(e.target).removeClass('has-error')
      dest = $(e.target).closest('td').find('.js-timeConvertTo')
      dest.val(inMinutes)
    )

    item

  @toMinutes: (hh) ->
    hh = hh.split(':')
    hour = parseInt(hh[0])
    minute = parseInt(hh[1])
    return if hour is NaN
    return if minute is NaN
    (hour * 60) + minute

  @toText: (m) ->
    m = parseInt(m)
    return if !m
    minutes = m % 60
    hours = Math.floor(m / 60)

    if minutes < 10
      minutes = "0#{minutes}"
    if hours < 10
      hours = "0#{hours}"

    "#{hours}:#{minutes}"
