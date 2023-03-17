# coffeelint: disable=camel_case_classes
# Provides full date and time picker
class App.UiElement.datetime extends App.UiElement.basedate
  @templateName: ->
    'datetime'

  @applyPickers: (item, attribute) ->
    super(item, attribute)

    item.find('.js-timepicker').timepicker()


  # returns array with date and time or false if cannot get date
  @currentInput: (item, attribute) ->
    result = super(item, attribute)

    if _.isArray(result)
      result.push item.find('.js-timepicker').val()

    result

  @validateInput: (currentInput) ->
    currentInput[0] isnt '' || currentInput[1] isnt ''

  @setNoTimestamp: (item) ->
    item.find('.js-timepicker').val('08:00')

  @setTimestamp: (item, timeObject) ->
    super(item, timeObject)

    hour   = timeObject.getHours()
    minute = timeObject.getMinutes()
    time   = "#{App.Utils.formatTime(hour,2)}:#{App.Utils.formatTime(minute,2)}"

    item.find('.js-timepicker').val(time)

  @buildTimestamp: (currentInput) ->
    timestamp = "#{currentInput[0]}T#{currentInput[1]}:00.000Z"
    time = new Date( Date.parse(timestamp) )
    return '' if isNaN time
    time.setMinutes( time.getMinutes() + time.getTimezoneOffset() )
    @log 'setNewTime', time.toString()
    time.toISOString().replace(/\d\d\.\d\d\dZ$/, '00.000Z')

  @dateSetter: ->
    'setDate'
