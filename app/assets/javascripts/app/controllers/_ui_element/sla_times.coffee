# coffeelint: disable=camel_case_classes
class App.UiElement.sla_times
  @render: (attribute, params = {}) ->

    # set default value
    if !params.first_response_time && params.first_response_time isnt 0
      params.first_response_time = 120

    item = $( App.view('generic/sla_times')(
      attribute: attribute
      first_response_time: params.first_response_time
      update_time: params.update_time
      solution_time: params.solution_time
      first_response_time_in_text: @toText(params.first_response_time)
      update_time_in_text: @toText(params.update_time)
      solution_time_in_text: @toText(params.solution_time)
    ) )

    # apply hour picker
    item.find('.js-timeConvertFrom').timepicker(
      maxHours: 999
    )

    # disable/enable rows
    item.find('.js-activateRow').bind('change', (e) ->
      element = $(e.target)
      row = element.closest('tr')
      if element.prop('checked')
        row.addClass('is-active')
      else
        row.removeClass('is-active')

        # reset data item
        row.find('.js-timeConvertFrom').val('')
        row.find('.js-timeConvertTo').val('')
    )

    # convert hours into minutes
    item.find('.js-timeConvertFrom').bind('keyup focus blur', (e) =>
      element = $(e.target)
      inText = element.val()
      row = element.closest('tr')
      dest = element.closest('td').find('.js-timeConvertTo')
      inMinutes = @toMinutes(inText)
      if !inMinutes
        element.addClass('has-error')
        dest.val('')
      else
        element.removeClass('has-error')
        dest.val(inMinutes)
      row.find('.js-activateRow').prop('checked', true)
      row.addClass('is-active')
    )

    # set initial active/inactive rows
    item.find('.js-timeConvertFrom').each(->
      row = $(@).closest('tr').find('.js-activateRow')
      if $(@).val()
        row.prop('checked', true)
      else
        row.prop('checked', false)
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
