class App.KnowledgeBaseCategory extends App.Model
  @configure 'KnowledgeBaseCategory', 'category_icon', 'parent_id', 'child_ids', 'translation_ids'
  @extend Spine.Model.Ajax
  @extend App.KnowledgeBaseActions

  url: ->
    @knowledge_base().generateURL('categories')

  uiUrl: (kb_locale, action = null) ->
    App.Utils.joinUrlComponents @knowledge_base().uiUrl(kb_locale), @uiUrlComponent(), action

  uiUrlComponent: ->
    "category/#{@id}"

  knowledge_base: ->
    App.KnowledgeBase.find(@knowledge_base_id)

  isEmpty: ->
    @children().length is 0 and @answers().length is 0

  remove: (options = {}) ->
    @removeTranslations(options)
    @children().forEach (elem) -> elem.remove(options)
    @answers().forEach  (elem) -> elem.remove(options)
    super

  categoriesForDropdown: (options) ->
    spacer = Array.apply(null, {length: options.nested}).map(-> '- ').join('')

    initial = [
      {
        value: @id
        name:  spacer + @guaranteedTitle(options.kb_locale.id)
      }
    ]

    @children().reduce (memo, elem) ->
      memo.concat elem.categoriesForDropdown(nested: options.nested + 1, kb_locale: options.kb_locale)
    , initial

  categoriesForSearch: (options = {}) ->
    result = [@guaranteedTitle(options.kb_locale.id)]

    check = @
    while check.parent()
      result.push(check.parent().guaranteedTitle(options.kb_locale.id))
      check = check.parent()

    if options.full || result.length <= 2
      result = result.reverse().join(' > ')
    else
      result = result.reverse()
      result = "#{result[0]} > .. > #{result[result.length - 1]}"

    result

  configure_attributes: (kb_locale = undefined) ->
    [
      {
        name:       'category_icon'
        model:      'category'
        display:    'Icon'
        tag:        'icon_picker'
        iconset:    @knowledge_base().iconset
        grid_width: '1/5'
        null:       false
        default:    @constructor.defaultIconFor(@knowledge_base())
        screen:
          agent_create:
            shown: true
      },
      {
        name:       'translation::title'
        model:      'translation'
        display:    'Title'
        tag:        'input'
        grid_width: '4/5'
        null:       false
        screen:
          agent_create:
            shown: true
      },
      {
        name:       'parent_id'
        model:      'category'
        display:    'Parent'
        tag:        'select'
        null:       true
        options:    @knowledge_base().categoriesForDropdown(includeRoot: true, kb_locale: kb_locale)
        grid_width: '1/2'
        screen:
          agent_create:
            tag:     'input'
            type:    'hidden'
            display: false
      }
    ]

  publicBaseUrl: (kb_locale) ->
    return null if @isNew()
    App.Utils.joinUrlComponents [@knowledge_base().publicBaseUrl(kb_locale), @id]

  @translatableClass: -> App.KnowledgeBaseCategoryTranslation
  @translatableForeignKey: -> 'category_id'
  @extend App.KnowledgeBaseTranslatable

  baseParams: ->
    { parent_id: @parent_id }

  children: ->
    return [] if @id == undefined

    App.KnowledgeBaseCategory
      .findAllByAttribute('parent_id', @id)
      .sort (a, b) -> a.position - b.position

  deepChildrenIds: ->
    children = @children()

    ids = children.map (elem) -> elem.deepChildrenIds()
    ids.push children.map (elem) -> elem.id

    _.flatten(ids)

  parent: ->
    App.KnowledgeBaseCategory.find(@parent_id)

  answers: ->
    App.KnowledgeBaseAnswer
      .findAllByAttribute('category_id', @id)
      .sort (a, b) -> a.position - b.position

  countDeepAnswers: ->
    category_ids = @deepChildrenIds()
    category_ids.push @id

    App.KnowledgeBaseAnswer
      .records
      .filter (elem) -> _.contains(category_ids, elem.category_id)
      .length

  findDeepAnswer: (callback) =>
    output = _.find(App.KnowledgeBaseAnswer.records, (record) =>
      if record.category_id isnt @id
        return false

      callback(record)
    )

    if output?
      return output

    _.find(App.KnowledgeBaseCategory.records, (record) =>
      if record.parent_id isnt @id
        return false

      record.findDeepAnswer(callback)
    )

  visibilityState: (kb_locale) ->
    if @visiblePublicly(kb_locale)
      'published'
    else if @visibleInternally(kb_locale)
      'internal'
    else
      'draft'

  visibleInternally: (kb_locale) =>
    @findDeepAnswer( (record) ->
      record.is_internally_published(kb_locale)
    )?

  visiblePublicly: (kb_locale) =>
    @findDeepAnswer( (record) ->
      record.is_published(kb_locale)
    )?

  objectName: ->
    'Category'

  @defaultIconFor: (kb) ->
    switch kb?.iconset
      when 'FontAwesome'
        'f115'
      when 'anticon'
        'e662'
      when 'material'
        'e94d'
      when 'ionicons'
        'f139'
      when 'Simple-Line-Icons'
        'e039'
