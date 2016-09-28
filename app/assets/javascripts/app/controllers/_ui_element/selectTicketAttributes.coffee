# coffeelint: disable=camel_case_classes
class App.UiElement.selectTicketAttributes extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    attributeOptionsArray = []
    for name, row of App.Ticket.attributesGet()

      # ignore passwords
      if row.type isnt 'password' && row.type isnt 'tag' && row.name isnt 'tags'
        nameTmp = row.name

        # get correct data name
        if row.name.substr(row.name.length-4,4) is '_ids'
          nameTmp = row.name.substr(0, row.name.length-4)
        else if row.name.substr(row.name.length-3,3) is '_id'
          nameTmp = row.name.substr(0, row.name.length-3)

        attributeOptionsArray.push(
          {
            value:  nameTmp
            name:   row.display
          }
        )

    attribute.sortBy = null
    attribute.options = attributeOptionsArray
    App.UiElement.select.render(attribute, params)
