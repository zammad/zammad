class App.KnowledgeBase extends App.Model
  @configure 'KnowledgeBase', 'iconset', 'color_highlight', 'color_header', 'translation_ids', 'locale_ids', 'homepage_layout', 'category_layout', 'custom_address'
  @extend Spine.Model.Ajax
  @extend App.KnowledgeBaseActions
  @url: @apiPath + '/knowledge_bases'

  @manageUrl: @apiPath + '/knowledge_bases/manage'
  manageUrl: (action = null) ->
    App.Utils.joinUrlComponents(@constructor.manageUrl, @id, action)

  publicBaseUrl: (kb_locale = undefined) ->
    # coffeelint: disable=indentation
    components = if @custom_address? && @custom_address[0] != '/'
                   ["http://#{@custom_address}"]
                 else if @custom_address?
                   [App.Utils.baseUrl(), @custom_address.substr(1, @custom_address.length - 1)]
                 else
                   [App.Utils.baseUrl(), 'help']
    # coffeelint: enable=indentation

    if kb_locale
      components.push kb_locale.systemLocale().locale

    App.Utils.joinUrlComponents components

  uiUrl: (kb_locale, suffix = undefined) ->
    App.Utils.joinUrlComponents @uiUrlComponent(), kb_locale.urlSuffix(), suffix

  uiUrlComponent: ->
    "#knowledge_base/#{@id}"

  categories: ->
    App.KnowledgeBaseCategory.all().filter (item) => item.knowledge_base_id == @id

  rootCategories: ->
    @categories()
      .filter (item) -> item.parent_id is null
      .sort (a, b) -> a.position - b.position

  kb_locales: ->
    App.KnowledgeBaseLocale.findAll(@kb_locale_ids)

  primaryKbLocale: ->
    @kb_locales().filter((elem) -> elem.primary)[0]

  knowledge_base: ->
    @

  isEmpty: ->
    @rootCategories().length is 0

  @translatableClass: -> App.KnowledgeBaseTranslation
  @translatableForeignKey: -> 'knowledge_base_id'
  @extend App.KnowledgeBaseTranslatable

  remove: (options = {}) ->
    @rootCategories().forEach (elem) -> elem.remove(options)
    @removeTranslations(options)
    super

  objectName: ->
    'Knowledge Base'

  categoriesForDropdown: (options = {}) ->
    initial = []
    if options.includeRoot
      initial.push { value: null, name: '>> Homepage <<'}

    initialNestLevel = if options.includeRoot
                         1
                       else
                         0

    @rootCategories().reduce (memo, elem) ->
      memo.concat elem.categoriesForDropdown(nested: initialNestLevel, kb_locale: options.kb_locale)
    , initial

  visibleInternally: (kb_locale) ->
    @active

  visiblePublicly: (kb_locale) ->
    @active

  attributes: ->
    attrs = super()

    attrs.kb_locales = @kb_locales().map (elem) -> elem.attributes()

    attrs

  @configure_attributes: [
    {
      name:    'translation::title'
      model:   'translation'
      display: 'Title'
      tag:     'input'
      null:    false
      screen:
        agent_edit:
          shown: true
    #}, {
      #name:     'homepage_layout'
      #model:    'knowledge_base'
      #display:  'Layout'
      #tag:      'radio'
      #null:     true
      #screen:
        #agent:
          #shown: true
      #options:  [
          #value: 'grid',
          #name: 'Grid'
          #graphic: 'knowledge_base_grid.svg'
        #,
          #value: 'list'
          #name: 'List'
          #graphic: 'knowledge_base_list.svg'
      #]
      ##relation: 'KnowledgeBaseLayout'
    }, {
      name:    'translation::footer_note'
      model:   'translation'
      display: 'Footer Note'
      tag:     'input'
      null:    false
      screen:
        agent_edit:
          shown: true
    }, {
      name: 'color_highlight'
      display: 'Icon & Link Color'
      tag: 'color'
      style: 'block'
      null: false
      screen:
        admin_style_color_highlight:
          display:    false
          horizontal: true
          shown:      true
    }, {
      name: 'color_header'
      display: 'Header Color'
      tag: 'color'
      style: 'block'
      null: false
      screen:
        admin_style_color_header:
          display:    false
          horizontal: true
          shown:      true
    # Layout picker is disabled in V1
    #}, {
    #  name:     'homepage_layout'
    #  display:  'Landing page layout'
    #  tag:      'radio_graphic'
    #  null:     false
    #  style:    'block'
    #  screen:
    #    admin_style_homepage:
    #      display:    false
    #      horizontal: true
    #      shown:      true
    #  options:  [
    #    {
    #      value:   'grid',
    #      name:    'Grid'
    #      graphic: 'knowledge_base_grid.svg'
    #    }, {
    #      value:   'list'
    #      name:    'List'
    #      graphic: 'knowledge_base_list.svg'
    #    }
    #  ]
    #}, {
    #  name:     'category_layout'
    #  display:  'Category page layout'
    #  tag:      'radio_graphic'
    #  null:     false
    #  style:    'block'
    #  screen:
    #    admin_style_category:
    #      display:    false
    #      horizontal: true
    #      shown:      true
    #  options:  [
    #    {
    #      value:   'grid',
    #      name:    'Grid'
    #      graphic: 'knowledge_base_grid.svg'
    #    }, {
    #      value:   'list'
    #      name:    'List'
    #      graphic: 'knowledge_base_list.svg'
    #    }
    #  ]
    }, {
      name:    'iconset'
      display: 'Icon Set'
      tag:     'iconset_picker'
      style:   'block'
      help:    'Every category in your knowledge base should be given a unique icon for maximum visual clarity. Each set below provides a wide range of icons to choose from, but beware-you can\'t mix and match different icons from different sets. Choose carefully!'
      null:    false
      screen:
        admin_style_iconset:
          shown: true
    }, {
      name: 'kb_locales'
      display: 'Languages'
      tag: 'multi_locales'
      style: 'block'
      null: false
      help: 'You can provide different versions of your knowledge base for different locales. Add a language below, then select it in the Knowledge Base Editor to add your translations.'
      screen:
        admin_languages:
          shown: true
        admin_create:
          shown: true
    }, {
      name:    'custom_address'
      display: 'Custom URL'
      tag:     'input'
      style:   'block'
      null:    true
      help:    'The default URL for your knowledge base is e.g. example.com or example.com/help. To serve it from a custom URL instead, enter the destination below (e.g., "/support", "example.com", or "example.com/support"). Then, follow the directions under "Web Server Configuration" to complete the process.'
      screen:
        admin_custom_address:
          shown: true
    }
  ]
