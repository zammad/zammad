# coffeelint: disable=camel_case_classes
class App.UiElement.sla_times
  @render: (attribute, params = {}) ->

    if !params.id && !params.first_response_time
      params.first_response_time = 120

    item = $( App.view('generic/sla_times')(
      attribute: attribute
      first_response_time: params.first_response_time
      response_time: params.response_time
      update_time: params.update_time
      solution_time: params.solution_time
      first_response_time_in_text: @toText(params.first_response_time)
      response_time_in_text: @toText(params.response_time)
      update_time_in_text: @toText(params.update_time)
      solution_time_in_text: @toText(params.solution_time)
    ) )

    # apply hour picker
    item.find('.js-timeConvertFrom').timepicker(
      maxHours: 999
    )

    # disable/enable rows
    item.find('.js-activateRow').on('change', (e) ->
      element = $(e.target)
      row = element.closest('tr')
      if element.prop('checked')
        row.addClass('is-active')

        if row.has('.js-updateTypeSelector').length > 0 && row.has('.js-updateTypeSelector:checked').length == 0
          row.find('.js-updateTypeSelector:first').prop('checked', true)
      else
        row.removeClass('is-active')

        # reset data item
        row.find('.js-timeConvertFrom').val('')
        row.find('.js-timeConvertTo').val('')
        row.find('.js-updateTypeSelector').attr('checked', false)
        row.find('.help-inline').empty()
        row.removeClass('has-error')
    )

    # convert hours into minutes
    item.find('.js-timeConvertFrom').on('keyup focus blur', (e) =>
      element = $(e.target)
      inText = element.val()

      row = element.closest('tr')

      row
        .find('.js-activateRow')
        .prop('checked', true)
        .trigger('change')

      row.addClass('is-active')

      row
        .find("[name='#{element.data('name')}']")
        .val(@toMinutes(inText) || '')
    )

    # toggle row on clicking name cell
    item.find('.js-forward-click').on('click', (e) ->
      $(e.currentTarget).closest('tr').find('.checkbox-replacement').trigger('click')
    )

    # toggle update type on clicking around the element
    item.find('.js-forward-radio').on('click', (e) ->
      elem = $(e.currentTarget).closest('p').find('.js-updateTypeSelector')

      elem.prop('checked', true)
      elem.trigger('change')
    )

    # focus time input on clicking surrounding cell
    item.find('.js-focus-input').on('click', (e) ->
      $(e.currentTarget)
        .find('.form-control:visible')
        .trigger('focus')
    )

    # show placeholder instead of 00:00
    item.find('.js-timeConvertFrom').on('changeTime.timepicker', (e) ->
      if $(e.currentTarget).val() == '00:00'
        $(e.currentTarget).val('')
    )

    # switch update/response times when type is selected accordingly
    item.find('.js-updateTypeSelector').on('change', (e) ->
      element = $(e.target)
      row = element.closest('tr')
      row.find('.js-activateRow').prop('checked', true)
      row.addClass('is-active')

      row
        .find('.js-timeConvertFrom')
        .addClass('hidden')
        .val('')

      row
        .find('.js-timeConvertTo')
        .val('')

      row
        .find("[data-name='#{element.val()}_time']")
        .removeClass('hidden')
    )

    # set initial active/inactive rows
    item.find('.js-timeConvertFrom').each(->
      row = $(@).closest('tr')
      checkbox = row.find('.js-activateRow')

      return if !$(@).val()

      checkbox.prop('checked', true)
      row.addClass('is-active')
    )

    item

  @toMinutes: (hh) ->
    hh = hh.split(':')
    hour = parseInt(hh[0])
    minute = parseInt(hh[1])
    return if hour is NaN
    return if minute is NaN
    return if hour is 0 and minute is 0
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
