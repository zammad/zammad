# coffeelint: disable=camel_case_classes
class App.UiElement.business_hours
  @render: (attributeOrig) ->

    attribute = _.clone(attributeOrig)
    attribute.nameRaw = attribute.name
    attribute.name = "{business_hours}#{attribute.name}"

    # Martin: our frontend doesn't create 24:00.
    # you have to check second values ('till') for 00:00
    # and convert them to 24:00
    if !attribute.value
      attribute.value =
        mon:
          active: true
          timeframes: [
            ['09:00','17:00']
          ]
        tue:
          active: true
          timeframes: [
            ['09:00','17:00']
          ]
        wed:
          active: true
          timeframes: [
            ['09:00','17:00']
          ]
        thu:
          active: true
          timeframes: [
            ['09:00','17:00']
          ]
        fri:
          active: true
          timeframes: [
            ['09:00','17:00']
          ]
        sat:
          active: false
          timeframes: [
            ['10:00','14:00']
          ]
        sun:
          active: false
          timeframes: [
            ['10:00','14:00']
          ]

    businessHours = new App.BusinessHours
      attribute: attribute
      hours: attribute.value

    businessHours.render()
    businessHours.el