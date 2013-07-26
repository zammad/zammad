class App.History extends App.Model
  @configure 'History', 'name'
  @extend Spine.Model.Ajax
  @url: '/histories'

  @_fillUp: (data) ->

    # add user
    data.created_by = App.User.find( data.created_by_id )

    # add possible actions
    if data.history_attribute_id
      data.attribute = App.HistoryAttribute.find( data.history_attribute_id )
    if data.history_type_id
      data.type      = App.HistoryType.find( data.history_type_id )
    if data.history_object_id
      data.object    = App.HistoryObject.find( data.history_object_id )

    return data

