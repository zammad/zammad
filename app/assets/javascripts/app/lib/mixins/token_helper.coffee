# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.TokenHelper
  @prepareTokenContent: (options = {}) ->
    { name, value, displayName, object, disabled, translate } = options

    # Use displayName if available (for tree structures with path separators)
    # Otherwise compute it from name using translation rules
    displayTextToUse = displayName || App.TokenHelper.computeNameValue(name, translate)

    content =
      name: displayTextToUse
      value: value

    content.object = object if object
    content.disabled = disabled if disabled?

    content

  @computeNameValue: (name, translate) ->
    return name if !name

    values = name.split('::')

    if translate
      values = values.map (val) -> App.i18n.translateInline(val)
    else
      values = values.map (val) -> val.trim()

    values.join(' › ') || '-'
