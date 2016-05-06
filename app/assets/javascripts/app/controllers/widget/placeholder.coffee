class App.WidgetPlaceholder extends App.Controller
  constructor: ->
    super

    if !@data
      @data = {}

    # remember instances
    @bindElements = []
    if @selector
      @bindElements = @$( @selector ).textmodule()
    else
      if @el.attr('contenteditable')
        @bindElements = @el.textmodule()
      else
        @bindElements = @$('[contenteditable]').textmodule()

    App.Setting.subscribe(@update, initFetch: true)

  update: =>
    all = []
    ignoreAttributes = {
      password: true
      active: true
    }
    ignoreSubAttributes = {
      password: true
      active: true
      created_at: true
      updated_at: true
    }
    for item in @objects
      list = {}
      if App[item.object] && App[item.object].configure_attributes
        for attribute in App[item.object].configure_attributes
          if !ignoreAttributes[attribute.name] && attribute.name.substr(attribute.name.length-4,attribute.name.length) isnt '_ids'
            list[attribute.name] = attribute
        for name in _.keys(list).sort()
          attribute = list[name]
          name = "\#{#{item.prefix}.#{attribute.name}}"
          content = "\#{#{item.prefix}.#{attribute.name}}"
          if attribute.relation
            subAttributes = {
              name: 'Name'
            }
            if App[attribute.relation] && App[attribute.relation].configure_attributes
              subList = {}
              subAttributes = {}
              for subAttribute in App[attribute.relation].configure_attributes
                if !ignoreSubAttributes[subAttribute.name] && subAttribute.name.substr(subAttribute.name.length-3,subAttribute.name.length) isnt '_id' && subAttribute.name.substr(subAttribute.name.length-4,subAttribute.name.length) isnt '_ids'
                  subList[subAttribute.name] = subAttribute
              for subName in _.keys(subList).sort()
                subAttributes[subName] = subList[subName].display
            relation = "#{item.prefix}.#{attribute.name.substr(0,attribute.name.length-3)}"
            for key, display of subAttributes
              name = "\#{#{relation}.#{key}}"
              content = "\#{#{relation}.#{key}}"
              all.push {
                id: name
                keywords: name
                name: "#{App.i18n.translateInline(item.display)} > #{App.i18n.translateInline(attribute.display)} > #{App.i18n.translateInline(display)}"
                content: content
              }
          else
            all.push {
              id: name
              keywords: name
              name: "#{App.i18n.translateInline(item.display)} > #{App.i18n.translateInline(attribute.display)}"
              content: content
            }

    # add config
    for setting in App.Setting.all()
      if setting.frontend && setting.preferences && setting.preferences.placeholder
        name = "#{App.i18n.translateInline('Config')} > #{App.i18n.translateInline(setting.title)}"
        content = "\#{config.#{setting.name}}"
        all.push {
          id: setting.name
          keywords: setting.name
          name: name
          content: content
        }

    # set new data
    if @bindElements[0]
      for element in @bindElements
        if $(element).data().plugin_textmodule
          $(element).data().plugin_textmodule.collection = all
