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

    item.find('.js-boolean').data('field-type', 'boolean')

    # add date picker
    attributeDatepicket =
      name: "#{attribute.name}_date"
      disable_feature: true
      class: 'form-control--small'
      validationContainer: 'self'
    datePicker = App.UiElement.date.render(attributeDatepicket)
    item.find('.js-datePicker').html(datePicker)

    # set active/inactive of date
    item.delegate('.js-active', 'click', (e) ->
      active = $(e.target).prop('checked')
      row = $(e.target).closest('tr')
      input = $(e.target).closest('tr').find('.js-summary')
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
    item.delegate('.js-remove', 'click', (e) ->
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
      if exists
        alert(App.i18n.translateInline('Aready exists!'))
        return

      # reset form input
      $(e.target).closest('tr').find('.js-summary').val('')

      # place new element

      template = App.view('calendar/holiday_selector_placeholder')(
        placeholderDate: date
        placeholderSummary: summary
        nameSummary: "public_holidays::#{date}::summary"
        nameActive: "public_holidays::#{date}::active"
      )
      item.find('.settings-list-controlRow').before(template)
      item.find('.js-boolean').data('field-type', 'boolean')
    )

    item
