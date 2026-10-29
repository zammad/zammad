# Cell callbacks shared by the controllers that list tickets in a table.
class App.TicketListCallbacks
  @userPopover: (value, object, attribute, attributes) ->
    return value if !object
    refObjectId = undefined
    if attribute.name is 'customer_id'
      refObjectId = object.customer_id
    if attribute.name is 'owner_id'
      refObjectId = object.owner_id
    return value if !refObjectId
    if attribute.name is 'customer_id' and refObjectId is 1
      # the header is shared by all rows, drop the popover a previous row has set
      delete attribute.class
      delete attribute.data
      return '-'
    attribute.class = 'user-popover'
    attribute.data =
      id: refObjectId
    value
