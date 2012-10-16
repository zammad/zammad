class App.Model extends Spine.Model

  displayName: ->
    return @name if @name
    if @realname
      return "#{@realname} <#{@email}>"
    if @firstname
      name = @firstname
      if @lastname
        if name
         name = name + ' '
        name = name + @lastname
      return name
    return '???'

  displayNameLong: ->
    return @name if @name
    if @firstname
      name = @firstname
      if @lastname
        if name
         name = name + ' '
        name = name + @lastname
      if @organization
        if typeof @organization is 'object'
          name = "#{name} (#{@organization.name})"
        else
          name = "#{name} (#{@organization})"
      else if @department
        name = "#{name} (#{@department})"
      return name
    return '???'

  @validate: ( data = {} ) ->
    return if !data['model'].configure_attributes

    # check attributes/each attribute of object
    errors = {}
    for attribute in data['model'].configure_attributes

      # only if attribute is not read only
      if !attribute.readonly

        # check required // if null is defined && null is false
        if 'null' of attribute && !attribute[null] 

          # key exists not in hash || value is '' || value is undefined 
          if !( attribute.name of data['params'] ) || data['params'][attribute.name] is '' || data['params'][attribute.name] is undefined
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
