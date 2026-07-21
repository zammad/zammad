# coffeelint: disable=camel_case_classes
class App.UiElement.audit_log_diff
  @render: (attribute, params = {}) ->
    valueFrom = params.value_from || {}
    valueTo   = params.value_to || {}

    keys = _.union(Object.keys(valueFrom), Object.keys(valueTo)).sort (a, b) -> a.toLowerCase().localeCompare(b.toLowerCase())

    # updated entries carry the authoritative list of changed attributes,
    # so that changed but masked values are shown as well
    changedAttributes = params.preferences?.changed_attributes

    lines = []
    for key in keys
      oldExists = key of valueFrom
      newExists = key of valueTo
      oldValue  = @stringifyValue(valueFrom[key])
      newValue  = @stringifyValue(valueTo[key])

      if changedAttributes
        continue if !_.contains(changedAttributes, key)
      else
        continue if oldExists && newExists && oldValue is newValue

      if oldExists
        lines.push(type: 'removed', sign: '-', text: "#{key}: #{oldValue}")
      if newExists
        lines.push(type: 'added', sign: '+', text: "#{key}: #{newValue}")

    $( App.view('generic/audit_log_diff')(attribute: attribute, lines: lines) )

  @stringifyValue: (value) ->
    return '' if value is null || value is undefined
    return value if _.isString(value)
    JSON.stringify(value)
