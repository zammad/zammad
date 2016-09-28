# coffeelint: disable=camel_case_classes
class App.UiElement.checkboxTicketAttributes extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    configureAttributes = App.Ticket.configure_attributes
    for row, localAttribute of App.Ticket.attributesGet()
      configureAttributes.push localAttribute
    attributeOptionsArray = []
    attributeOptions = {}
    for row in configureAttributes

      # ignore passwords
      if row.type isnt 'password' && row.type isnt 'tag' && row.name isnt 'tags'
        nameTmp = row.name

        # get correct data name
        if row.name.substr(row.name.length-4,4) is '_ids'
          nameTmp = row.name.substr(0, row.name.length-4)
        else if row.name.substr(row.name.length-3,3) is '_id'
          nameTmp = row.name.substr(0, row.name.length-3)

        if !attributeOptions[ nameTmp ]
          attributeOptions[ nameTmp ] = row.display
          attributeOptionsArray.push(
            {
              value:  nameTmp
              name:   row.display
            }
          )
    attribute.item_class = 'checkbox'
    attribute.options = attributeOptions
    App.UiElement.checkbox.render(attribute, params)
