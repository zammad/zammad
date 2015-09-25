# coffeelint: disable=camel_case_classes
class App.UiElement.holiday_selector
  @render: (attribute, params) ->

    days = {}
    if attribute.value
      days = attribute.value
      days_sorted = _.keys(days).sort()
      days_new = {}
      for day in days_sorted
        days_new[day] = days[day]

    item = $( App.view('calendar/holiday_selector')( attribute: attribute, days: days_new ) )

    # add date picker
    attributeDatepicket =
      name: "#{attribute.name}_date"
      disable_feature: true
    datePicker = App.UiElement.date.render(attributeDatepicket)
    item.find('.js-datePicker').html(datePicker)

    # set active/inactive of date
    item.find('.js-active').bind('click', (e) ->
      active = $(e.target).prop('checked')
      row = $(e.target).closest('tr')
      input = $(e.target).closest('tr').find('.js-description')
      if !active
        row.addClass('is-inactive')
        input.prop('readonly', true)
        input.addClass('is-disabled')
      else
        row.removeClass('is-inactive')
        input.prop('readonly', false)
        input.removeClass('is-disabled')
    )

    # remove date
    item.find('.js-remove').bind('click', (e) ->
      $(e.target).closest('tr').remove()
    )

    # catch enter / apply add
    item.find('.js-summary').bind( 'keydown', (e) ->
      return if e.which isnt 13
      e.preventDefault()
      item.find('.js-add').click()
    )

    # add date
    item.find('.js-add').bind('click', (e) ->
      date = $(e.target).closest('tr').find('[name="{date}public_holidays_date"]').val()
      return if !date
      summary = $(e.target).closest('tr').find('.js-summary').val()
      return if !summary

      # check if entry already exists
      exists = item.find("[data-date=#{date}]").get(0)
      return if exists

      # reset form input
      $(e.target).closest('tr').find('.js-summary').val('')

      # place new element
      template = item.find('.js-placeholder').clone()
      template.removeClass('hidden').removeClass('js-placeholder')
      template.attr('data-date', date)
      template.find('.js-date').html(App.i18n.translateDate(date))
      template.find('.js-active').attr('name', "{boolean}public_holidays::#{date}::active")
      template.find('.js-summary').attr('name', "public_holidays::#{date}::summary")
      template.find('.js-summary').val(summary)
      item.find('.js-placeholder').before(template)
    )

    item
