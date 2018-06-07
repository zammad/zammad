# coffeelint: disable=camel_case_classes
# Provides date-only picker
class App.UiElement.date extends App.UiElement.basedate
  @templateName: ->
    'date'

  @buildTimestamp: (currentInput) ->
    currentInput[0]

  @dateSetter: ->
    'setUTCDate'
