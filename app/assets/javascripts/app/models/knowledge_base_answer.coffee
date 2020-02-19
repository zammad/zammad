class App.KnowledgeBaseAnswer extends App.Model
  @configure 'KnowledgeBaseAnswer', 'category_id', 'translation_ids', 'archived_at', 'internal_at', 'published_at', 'attachments'
  @extend Spine.Model.Ajax
  @extend App.KnowledgeBaseActions
  @extend App.KnowledgeBaseCanBePublished

  @serverClassName: 'KnowledgeBase::Answer'

  url: ->
    @knowledge_base().generateURL('answers')

  uiUrl: (kb_locale, action = null) ->
    App.Utils.joinUrlComponents @knowledge_base().uiUrl(kb_locale), @uiUrlComponent(), action

  uiUrlComponent: ->
    "answer/#{@id}"

  knowledge_base: ->
    App.KnowledgeBase.find(@category().knowledge_base_id)

  category: ->
    App.KnowledgeBaseCategory.find(@category_id)

  @configure_attributes = [
      {
        name:       'translation::title'
        model:      'translation'
        display:    'Title'
        tag:        'input'
        grid_width: '1/2'
      },
  ]

  configure_attributes: (kb_locale = undefined) ->
    [
      {
        name:       'translation::title'
        model:      'translation'
        display:    'Title'
        tag:        'input'
        grid_width: '1/2'
        null:       false
        screen:
          agent_create:
            shown: true
      },
      {
        name:       'category_id'
        model:      'answer'
        display:    'Category'
        tag:        'select'
        null:       false
        options:    @knowledge_base().categoriesForDropdown(kb_locale: kb_locale)
        grid_width: '1/2'
        screen:
          agent_create:
            tag:     'input'
            type:    'hidden'
            display: false
      },
      {
        name:    'translation::content::body'
        model:   'translation'
        buttons: [
          'link'
          'link_answer'
          'insert_image'
          'embed_video'
        ]
        display: 'Content'
        tag:     'richtext'
        null:    true
      }
    ]

  publicBaseUrl: (kb_locale) ->
    return null if @isNew()
    App.Utils.joinUrlComponents [@category().publicBaseUrl(kb_locale), @id]

  @translatableClass: -> App.KnowledgeBaseAnswerTranslation
  @translatableForeignKey: -> 'answer_id'
  @extend App.KnowledgeBaseTranslatable

  remove: (options = {}) ->
    @removeTranslations(options)
    super

  baseParams: ->
    { category_id: @category_id }

  category: ->
    App.KnowledgeBaseCategory.find(@category_id)

  objectName: ->
    'Answer'

  visibleInternally: (kb_locale) =>
    @is_internally_published(kb_locale)
