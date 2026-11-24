# coffeelint: disable=camel_case_classes
class App.UiElement.audit_log_diff
  @SENSITIVE_MASK: '**********'

  @render: (attribute, params = {}) ->
    valueFrom = params.value_from || {}
    valueTo   = params.value_to || {}

    # updated entries carry the authoritative list of changed attributes,
    # so that changed but masked values are shown as well
    changedAttributes = params.preferences?.changed_attributes

    lines = []
    for key in @sortedKeys(valueFrom, valueTo)
      oldExists = key of valueFrom
      newExists = key of valueTo
      oldValue  = @stringifyValue(valueFrom[key])
      newValue  = @stringifyValue(valueTo[key])

      if changedAttributes
        continue if !_.contains(changedAttributes, key)
      else
        continue if oldExists && newExists && oldValue is newValue

      # without visible or masked nested changes the whole value is shown
      nestedLines = @nestedLines(key, valueFrom[key], valueTo[key])
      nestedLines = @maskedLines(key, valueFrom[key], valueTo[key]) if _.isEmpty(nestedLines)
      if !_.isEmpty(nestedLines)
        lines = lines.concat(nestedLines)
        continue

      if oldExists
        lines.push(type: 'removed', sign: '-', text: "#{key}: #{oldValue}")
      if newExists
        lines.push(type: 'added', sign: '+', text: "#{key}: #{newValue}")

    $( App.view('generic/audit_log_diff')(attribute: attribute, lines: lines) )

  # hashes on both sides are compared key by key, so that only the changed nested values are shown
  @nestedLines: (path, valueFrom, valueTo) ->
    @leafLines(path, valueFrom, valueTo, (oldExists, newExists, oldValue, newValue) -> !oldExists || !newExists || oldValue isnt newValue)

  # changed hashes without visible differences can only differ in their masked values
  @maskedLines: (path, valueFrom, valueTo) ->
    @leafLines(path, valueFrom, valueTo, (oldExists, newExists, oldValue, newValue) => oldValue is @SENSITIVE_MASK && newValue is @SENSITIVE_MASK)

  @leafLines: (path, valueFrom, valueTo, isShown) ->
    return [] if !$.isPlainObject(valueFrom) || !$.isPlainObject(valueTo)

    lines = []
    for key in @sortedKeys(valueFrom, valueTo)
      nestedPath = "#{path}.#{key}"

      if $.isPlainObject(valueFrom[key]) && $.isPlainObject(valueTo[key])
        lines = lines.concat(@leafLines(nestedPath, valueFrom[key], valueTo[key], isShown))
        continue

      oldExists = key of valueFrom
      newExists = key of valueTo
      oldValue  = @stringifyValue(valueFrom[key])
      newValue  = @stringifyValue(valueTo[key])

      continue if !isShown(oldExists, newExists, oldValue, newValue)

      if oldExists
        lines.push(type: 'removed', sign: '-', text: "#{nestedPath}: #{oldValue}")
      if newExists
        lines.push(type: 'added', sign: '+', text: "#{nestedPath}: #{newValue}")

    lines

  @sortedKeys: (valueFrom, valueTo) ->
    _.union(Object.keys(valueFrom), Object.keys(valueTo)).sort (a, b) -> a.toLowerCase().localeCompare(b.toLowerCase())

  @stringifyValue: (value) ->
    return '' if value is null || value is undefined
    return value if _.isString(value)
    JSON.stringify(value)
