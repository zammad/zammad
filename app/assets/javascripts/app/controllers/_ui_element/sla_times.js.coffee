class App.UiElement.sla_times
  @render: (attribute, params = {}) ->

    item = $( App.view('generic/sla_times')(
      attribute: attribute
      first_response_time: params.first_response_time
      update_time: params.update_time
      solution_time: params.solution_time
      first_response_time_in_text: @toText(params.first_response_time)
      update_time_in_text: @toText(params.update_time)
      solution_time_in_text: @toText(params.solution_time)
    ) )

    item.find('.js-activateRow').bind('change', (e) =>
      element = $(e.target)
      if element.prop('checked')
        element.closest('tr').addClass('is-active')
      else
        element.closest('tr').removeClass('is-active')
        element.closest('tr').find('.js-timeConvertFrom').val('')
    )

    item.find('.js-timeConvertFrom').bind('keyup', (e) =>
      element = $(e.target)
      inText = element.val()
      inMinutes = @toMinutes(inText)
      if !inMinutes
        element.addClass('has-error')
      else
        element.removeClass('has-error')
      dest = element.closest('td').find('.js-timeConvertTo')
      dest.val(inMinutes)
      element.closest('tr').find('.js-activateRow').prop('checked', true)
      element.closest('tr').addClass('is-active')
    )

    item.find('.js-timeConvertFrom').each(->
      if $(@).val()
        $(@).closest('tr').find('.js-activateRow').prop('checked', true)
      else
        $(@).closest('tr').find('.js-activateRow').prop('checked', false)
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
