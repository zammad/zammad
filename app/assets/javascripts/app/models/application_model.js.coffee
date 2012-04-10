class App.Model extends Spine.Model
  
  validate: (data = {}) ->
#    console.log 'vali', @
#    console.log 'vali', params, '@', @
#    console.log 'validate', params, @configure_attributes, @, App.User.configure_attributes
    # check if @constructor.configure_attributes is used
    return if !@constructor.configure_attributes

    errors = {}
    for attribute in @constructor.configure_attributes
      if !attribute.readonly 
        
        # check required
        if 'null' of attribute && !attribute[null] && !@[attribute.name]
          errors[attribute.name] = 'is required'

        # check confirm password
        if data.form && attribute.type is 'password' && @[attribute.name]

          # get confirm password
          if @[attribute.name] isnt @["#{attribute.name}_confirm"]
            console.log 'aaa', @[attribute.name], @["#{attribute.name}_confirm"], attribute[null]
            errors[attribute.name] = 'didn\'t match'
            errors["#{attribute.name}_confirm"] = ''

    # return error object
    for key, msg of errors
#      console.log 'e', errors
      return errors
      
    return