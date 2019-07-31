# coffeelint: disable=camel_case_classes
class App.UiElement.ical_feed extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    icalFeeds = App.Config.get('ical_feeds') || {}
    icalFeedsSorted = App.Utils.sortByValue(icalFeeds)
    item = $( App.view('generic/ical_feed')( attribute: attribute, icalFeeds: icalFeedsSorted ) )

    updateCheckList = ->
      return if item.find('.js-checkList').prop('checked')
      return if !item.find('.js-list').val()
      item.find('.js-checkList').prop('checked', true)
      item.find('.js-checkManual').prop('checked', false)

    updateCheckManual = ->
      return if item.find('.js-checkManual').prop('checked')
      item.find('.js-checkList').prop('checked', false)
      item.find('.js-checkManual').prop('checked', true)

    updateShadow = (selected) ->
      if !selected
        selected = item.find('.js-check:checked').attr('value')
      if selected is 'manual'
        item.find('.js-shadow').val( item.find('.js-manual').val() )
      else
        item.find('.js-shadow').val( item.find('.js-list').val() )

    # set initial state
    if icalFeeds[attribute.value]
      updateCheckList()
    else
      updateCheckManual()
      item.find('.js-manual').val(attribute.value)

    item.find('.js-check').bind('change', ->
      updateShadow()
    )

    item.find('.js-list').bind('click change', ->
      updateCheckList()
      updateShadow('list')
    )

    item.find('.js-manual').bind('keyup focus blur', ->
      updateCheckManual()
      updateShadow('manual')
    )

    item
