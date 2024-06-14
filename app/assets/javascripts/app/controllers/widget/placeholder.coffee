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
            if Object.keys(App[attribute.relation].allowedReplaceTagsFunctionMapping).length > 0
              for functionMapping in Object.values(App[attribute.relation].allowedReplaceTagsFunctionMapping)
                name = "\#{#{relation}.#{functionMapping.placeholder_content}}"
                content = "\#{#{relation}.#{functionMapping.placeholder_content}}"
                all.push {
                  id: name
                  keywords: name
                  name: "#{App.i18n.translateInline(item.display)} > #{App.i18n.translateInline(attribute.display)} > #{App.i18n.translateInline(functionMapping.placeholder_display)}"
                  content: content
                }
          else
            all.push {
              id: name
              keywords: name
              name: "#{App.i18n.translateInline(item.display)} > #{App.i18n.translateInline(attribute.display)}"
              content: content
            }
      if Object.keys(App[item.object].allowedReplaceTagsFunctionMapping).length > 0
        for functionMapping in Object.values(App[item.object].allowedReplaceTagsFunctionMapping)
          name = "\#{#{item.prefix}.#{functionMapping.placeholder_content}}"
          content = "\#{#{item.prefix}.#{functionMapping.placeholder_content}}"
          all.push {
            id: name
            keywords: name
            name: "#{App.i18n.translateInline(item.display)} > #{App.i18n.translateInline(functionMapping.placeholder_display)}"
            content: content
          }

    # Add HTML format of articles
    if (_.filter(all, (item) -> item.name.startsWith('Article')).length > 0)
      all.push {
        # coffeelint: disable=no_interpolation_in_single_quotes
        name: __('Article > Text (HTML)'),
        id: '#{article.body_as_html}',
        keywords: '#{article.body_as_html}',
        content: '#{article.body_as_html}',
        # coffeelint: enable=no_interpolation_in_single_quotes
      }

    # modify article placeholders
    replaces = [
      { display: __('Last Article'), name: 'last_article' },
      { display: __('Last Internal Article'), name: 'last_internal_article' },
      { display: __('Last External Article'), name: 'last_external_article' },
      { display: __('Created Article'), name: 'created_article' },
      { display: __('Created Internal Article'), name: 'created_internal_article' },
      { display: __('Created External Article'), name: 'created_external_article' },
    ]

    for item in all
      if item.name.startsWith('Article')
        for replace in replaces
          all.push {
            name: item.name.replace('Article', App.i18n.translateInline(replace.display))
            content: item.content.replace('article', replace.name)
            id: item.id.replace('article', replace.name)
            keywords: item.keywords.replace('article', replace.name)
          }

    all = _.filter(all, (item) ->
      return !item.name.startsWith('Article')
    )

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
