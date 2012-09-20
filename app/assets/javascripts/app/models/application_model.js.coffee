class App.Model extends Spine.Model

  @validate: ( data = {} ) ->
    return if !data['model'].configure_attributes

    errors = {}
    for attribute in data['model'].configure_attributes
      if !attribute.readonly 
        
        # check required
        if 'null' of attribute && !attribute[null] && !data['params'][attribute.name]
          errors[attribute.name] = 'is required'

        # check confirm password
        if attribute.type is 'password' && data['params'][attribute.name] && "#{attribute.name}_confirm" of data['params']

          # get confirm password
          if data['params'][attribute.name] isnt data['params']["#{attribute.name}_confirm"]
            console.log 'aaa', data['params'][attribute.name], data['params']["#{attribute.name}_confirm"], attribute[null]
            errors[attribute.name] = 'didn\'t match'
            errors["#{attribute.name}_confirm"] = ''

    # return error object
    return errors if !_.isEmpty(errors)

    # return no errors
    return

  validate: ->
    App.Model.validate(
      model: @constructor,
      params: @,
    )
